import Combine
import Foundation
import MusicKit
import UIKit

@MainActor
final class MusicAuthorizationManager: ObservableObject {
    @Published private(set) var status: MusicAuthorization.Status = MusicAuthorization.currentStatus

    func refresh() {
        status = MusicAuthorization.currentStatus
    }

    func requestPermission() async {
        status = await MusicAuthorization.request()
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

@MainActor
final class AppleMusicManager: ObservableObject {
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    @Published private(set) var searchResults: [WorkoutMusicSearchResult] = []
    @Published private(set) var libraryPlaylists: [WorkoutMusicSearchResult] = []
    @Published private(set) var nowPlayingTitle = "Not playing"
    @Published private(set) var nowPlayingSubtitle = "Apple Music"
    @Published private(set) var nowPlayingArtworkURL: URL?
    @Published private(set) var isPlaying = false
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var subscriptionAllowsPlayback = true
    @Published private(set) var hasPlayableQueue = false

    static let shared = AppleMusicManager()

    private let player = ApplicationMusicPlayer.shared
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        observePlayer()
    }

    func refreshAuthorization() {
        authorizationStatus = MusicAuthorization.currentStatus
    }

    func requestPermissionIfNeeded() async {
        if MusicAuthorization.currentStatus == .notDetermined {
            authorizationStatus = await MusicAuthorization.request()
        } else {
            authorizationStatus = MusicAuthorization.currentStatus
        }
    }

    func checkSubscription() async {
#if targetEnvironment(simulator)
        subscriptionAllowsPlayback = false
        errorMessage = "Apple Music playback needs a real device. Search and setup can work here, but playback will not start in Simulator."
        return
#endif

        do {
            let subscription = try await MusicSubscription.current
            subscriptionAllowsPlayback = subscription.canPlayCatalogContent
            if subscription.canPlayCatalogContent == false {
                errorMessage = "Apple Music playback may require an active Apple Music subscription."
            }
        } catch {
            subscriptionAllowsPlayback = false
            errorMessage = "Apple Music playback is unavailable right now."
        }
    }

    func search(term: String) async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }

        guard authorizationStatus == .authorized else {
            await requestPermissionIfNeeded()
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            var request = MusicCatalogSearchRequest(term: trimmed, types: [Song.self, Album.self, Playlist.self])
            request.limit = 8
            let response = try await request.response()
            searchResults = Self.results(from: response)
        } catch {
            errorMessage = "Apple Music search failed. Check your connection and try again."
            searchResults = []
        }

        isSearching = false
    }

    func fetchLibraryPlaylists() async {
        guard authorizationStatus == .authorized else { return }

        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 12
            let response = try await request.response()
            libraryPlaylists = response.items.map { playlist in
                WorkoutMusicSearchResult(
                    id: playlist.id.rawValue,
                    musicItemId: playlist.id.rawValue,
                    musicItemType: .playlist,
                    title: playlist.name,
                    subtitle: "Library Playlist",
                    artworkURL: playlist.artwork?.url(width: 160, height: 160)
                )
            }
        } catch {
            libraryPlaylists = []
        }
    }

    func play(selection: WorkoutMusicSelection) async {
        guard authorizationStatus == .authorized else {
            await requestPermissionIfNeeded()
            return
        }

        await checkSubscription()
        guard subscriptionAllowsPlayback else { return }

        do {
            var didPrepareQueue = false

            switch selection.musicItemType {
            case .song:
                if let song = try await fetchSong(id: selection.musicItemId) {
                    player.queue = [song]
                    didPrepareQueue = true
                }
            case .album:
                if let album = try await fetchAlbum(id: selection.musicItemId) {
                    player.queue = [album]
                    didPrepareQueue = true
                }
            case .playlist:
                if let playlist = try await fetchPlaylist(id: selection.musicItemId) {
                    player.queue = [playlist]
                    didPrepareQueue = true
                }
            }

            guard didPrepareQueue else {
                errorMessage = "This Apple Music item is no longer available."
                hasPlayableQueue = false
                return
            }

            hasPlayableQueue = true
            try await player.play()
            nowPlayingTitle = selection.title
            nowPlayingSubtitle = selection.subtitle
            nowPlayingArtworkURL = selection.artworkURL
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = "Could not play this Apple Music item."
        }
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func resume() async {
        guard hasPlayableQueue else {
            errorMessage = "Choose workout music first, then press Play."
            return
        }

        do {
            try await player.play()
            isPlaying = true
        } catch {
            errorMessage = "Could not resume Apple Music playback."
        }
    }

    func togglePlayback() async {
        if isPlaying {
            pause()
        } else {
            await resume()
        }
    }

    func skipToNext() async {
        do {
            try await player.skipToNextEntry()
        } catch {
            errorMessage = "Could not skip to the next track."
        }
    }

    func skipToPrevious() async {
        do {
            try await player.skipToPreviousEntry()
        } catch {
            errorMessage = "Could not go back to the previous track."
        }
    }

    func stop() {
        player.stop()
        isPlaying = false
        hasPlayableQueue = false
        nowPlayingTitle = "Not playing"
        nowPlayingSubtitle = "Apple Music"
        nowPlayingArtworkURL = nil
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func observePlayer() {
        player.state.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.isPlaying = self?.player.state.playbackStatus == .playing
                }
            }
            .store(in: &cancellables)
    }

    private func fetchSong(id: String) async throws -> Song? {
        var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
        request.limit = 1
        return try await request.response().items.first
    }

    private func fetchAlbum(id: String) async throws -> Album? {
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: MusicItemID(id))
        request.limit = 1
        return try await request.response().items.first
    }

    private func fetchPlaylist(id: String) async throws -> Playlist? {
        var request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(id))
        request.limit = 1
        return try await request.response().items.first
    }

    private static func results(from response: MusicCatalogSearchResponse) -> [WorkoutMusicSearchResult] {
        let songs = response.songs.map { song in
            WorkoutMusicSearchResult(
                id: "song-\(song.id.rawValue)",
                musicItemId: song.id.rawValue,
                musicItemType: .song,
                title: song.title,
                subtitle: song.artistName,
                artworkURL: song.artwork?.url(width: 160, height: 160)
            )
        }

        let albums = response.albums.map { album in
            WorkoutMusicSearchResult(
                id: "album-\(album.id.rawValue)",
                musicItemId: album.id.rawValue,
                musicItemType: .album,
                title: album.title,
                subtitle: album.artistName,
                artworkURL: album.artwork?.url(width: 160, height: 160)
            )
        }

        let playlists = response.playlists.map { playlist in
            WorkoutMusicSearchResult(
                id: "playlist-\(playlist.id.rawValue)",
                musicItemId: playlist.id.rawValue,
                musicItemType: .playlist,
                title: playlist.name,
                subtitle: playlist.curatorName ?? "Apple Music Playlist",
                artworkURL: playlist.artwork?.url(width: 160, height: 160)
            )
        }

        return Array((songs + albums + playlists).prefix(20))
    }
}

typealias AppleMusicService = AppleMusicManager
