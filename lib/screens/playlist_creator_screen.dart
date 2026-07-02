import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../controllers/config_controller.dart';

class PlaylistCreatorScreen extends StatefulWidget {
  const PlaylistCreatorScreen({super.key});

  @override
  State<PlaylistCreatorScreen> createState() => _PlaylistCreatorScreenState();
}

class _PlaylistCreatorScreenState extends State<PlaylistCreatorScreen> {
  final ConfigController controller = Get.find<ConfigController>();

  // State of the current editing playlist
  int? editingPlaylistIndex;
  final TextEditingController playlistNameController = TextEditingController();
  final RxList<int> currentTracks = <int>[].obs; // Indexes in SongMaster

  // Search track
  final RxString searchTrackQuery = "".obs;

  @override
  void initState() {
    super.initState();
    _startNewPlaylist();
  }

  @override
  void dispose() {
    playlistNameController.dispose();
    super.dispose();
  }

  void _startNewPlaylist() {
    setState(() {
      editingPlaylistIndex = null;
      playlistNameController.clear();
      currentTracks.clear();
    });
  }

  void _loadPlaylist(int index, Playlist playlist) {
    setState(() {
      editingPlaylistIndex = index;
      playlistNameController.text = playlist.name;
      currentTracks.assignAll(playlist.sc);
    });
  }

  void _savePlaylist() {
    final name = playlistNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        "Required",
        "Please enter a playlist name",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (currentTracks.isEmpty) {
      Get.snackbar(
        "Empty Playlist",
        "Please add at least one track to the playlist",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final playlist = Playlist(name: name, sc: currentTracks.toList());

    if (editingPlaylistIndex != null) {
      controller.updatePlaylist(editingPlaylistIndex!, playlist);
      Get.snackbar(
        "Updated",
        "Playlist '$name' updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        colorText: Colors.white,
      );
    } else {
      controller.addPlaylist(playlist);
      editingPlaylistIndex = controller.playlists.length - 1;
      Get.snackbar(
        "Created",
        "Playlist '$name' saved successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        colorText: Colors.white,
      );
    }
  }

  void _deletePlaylist(int index, String name) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          "Delete Playlist",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          "Are you sure you want to delete '$name'?",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePlaylist(index);
              if (editingPlaylistIndex == index) {
                _startNewPlaylist();
              } else if (editingPlaylistIndex != null &&
                  editingPlaylistIndex! > index) {
                editingPlaylistIndex = editingPlaylistIndex! - 1;
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showThreeColumns = constraints.maxWidth > 1150;

          if (showThreeColumns) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Left Column: Saved Playlists
                  SizedBox(
                    width: 250,
                    child: _buildSavedPlaylistsPanel(theme, isDark),
                  ),
                  const SizedBox(width: 20),

                  // 2. Right Column: Composer
                  Expanded(child: _buildComposerPanel(theme, isDark)),
                ],
              ),
            );
          } else {
            // Fold into a stacked scrollable layout on smaller widths
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 350,
                    child: _buildSavedPlaylistsPanel(theme, isDark),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 600,
                    child: _buildComposerPanel(theme, isDark),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // PANEL 1: Saved Playlists List
  Widget _buildSavedPlaylistsPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Saved Playlists",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: _startNewPlaylist,
                tooltip: "Create New Playlist",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            height: 1,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (controller.playlists.isEmpty) {
                return Center(
                  child: Text(
                    "No playlists saved.",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.playlists.length,
                itemBuilder: (context, idx) {
                  final playlist = controller.playlists[idx];
                  final isSelected = editingPlaylistIndex == idx;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        "${playlist.sc.length} tracks",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        onPressed: () => _deletePlaylist(idx, playlist.name),
                        tooltip: "Delete",
                      ),
                      onTap: () => _loadPlaylist(idx, playlist),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // PANEL 2: Playlist Composer
  Widget _buildComposerPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Playlist Composer",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Define a playlist title and sequence of announcement tracks.",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _savePlaylist,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: Text(
                  editingPlaylistIndex != null ? "Update" : "Save Playlist",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Playlist Name Field
          TextField(
            controller: playlistNameController,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Playlist Title / Name",
              hintText: "e.g., Morning Devotion",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onChanged: (val) {
              setState(() {}); // trigger rebuild to update live JSON preview
            },
          ),
          const SizedBox(height: 16),

          // Search Song Master items
          TextField(
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search track catalog to add...",
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              fillColor: theme.colorScheme.onSurface.withOpacity(0.02),
            ),
            onChanged: (val) => searchTrackQuery.value = val,
          ),
          const SizedBox(height: 8),

          // Search matches list (compact grid/list)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Obx(() {
              var matches = controller.songMaster.asMap().entries.toList();
              if (searchTrackQuery.value.isNotEmpty) {
                final query = searchTrackQuery.value.toLowerCase();
                matches = matches.where((e) {
                  return e.value.name.toLowerCase().contains(query) ||
                      e.value.code.toLowerCase().contains(query) ||
                      e.value.folder.toLowerCase().contains(query);
                }).toList();
              }

              if (matches.isEmpty) {
                return Center(
                  child: Text(
                    "No tracks match search",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 11,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: matches.length,
                itemBuilder: (context, idx) {
                  final songIdx = matches[idx].key;
                  final item = matches[idx].value;
                  return InkWell(
                    onTap: () {
                      currentTracks.add(songIdx);
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: item.mode == 'SYS'
                                      ? Colors.indigo.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  item.mode,
                                  style: TextStyle(
                                    color: item.mode == 'SYS'
                                        ? Colors.indigoAccent
                                        : Colors.orangeAccent,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),

          // Playlist Tracks Reorderable List
          Text(
            "Tracks Sequence (SC)",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (currentTracks.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Playlist is empty. Click tracks from the grid above to build the sequence.",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.38),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = currentTracks.removeAt(oldIndex);
                  currentTracks.insert(newIndex, item);
                },
                children: List.generate(currentTracks.length, (idx) {
                  final smIndex = currentTracks[idx];
                  final item =
                      (smIndex >= 0 && smIndex < controller.songMaster.length)
                      ? controller.songMaster[smIndex]
                      : SongMasterItem(
                          count: smIndex,
                          code: 'ERR',
                          folder: 'ERR',
                          mode: 'ERR',
                          name: 'Unknown',
                        );

                  return Card(
                    key: ValueKey("playlist_track_${idx}_$smIndex"),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.drag_handle,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Text(
                        "Code: ${item.code} | Category: ${item.folder}",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: () {
                          currentTracks.removeAt(idx);
                        },
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}
