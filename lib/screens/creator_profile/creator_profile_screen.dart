import 'dart:io';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/creator_profile.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/creator_profile_provider.dart';
import 'package:charmy_craft_studio/state/profile_update_provider.dart';
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const List<String> supportedIcons = [
  'whatsapp', 'youtube', 'telegram', 'instagram', 'pinterest', 'redbubble', 'linkedin', 'email', 'link'
];

IconData _getIconForName(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'whatsapp': return FontAwesomeIcons.whatsapp;
    case 'youtube': return FontAwesomeIcons.youtube;
    case 'telegram': return FontAwesomeIcons.telegram;
    case 'instagram': return FontAwesomeIcons.instagram;
    case 'pinterest': return FontAwesomeIcons.pinterest;
    case 'redbubble': return FontAwesomeIcons.bagShopping;
    case 'linkedin': return FontAwesomeIcons.linkedin;
    case 'email': return FontAwesomeIcons.solidEnvelope;
    default: return FontAwesomeIcons.link;
  }
}


class CreatorProfileScreen extends ConsumerWidget {
  const CreatorProfileScreen({super.key});

  void _launchURL(String urlString) async {
    if (urlString.contains('@') && !urlString.startsWith('mailto:')) {
      urlString = 'mailto:$urlString';
    } else if (!urlString.startsWith('http') && !urlString.contains('@')) {
      urlString = 'https://$urlString';
    }

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, CreatorProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => EditProfileSheet(profile: profile),
    );
  }

  Future<void> _updateCreatorImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (pickedFile != null) {
        final cropper = ImageCropper();

        final CroppedFile? croppedFile = await cropper.cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: Theme.of(context).colorScheme.secondary,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
              cropStyle: CropStyle.circle,
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioLockEnabled: true,
              cropStyle: CropStyle.circle,
            ),
          ],
        );

        if (croppedFile != null) {
          final imageFile = File(croppedFile.path);
          await ref.read(profileUpdateProvider.notifier).updateCreatorPublicProfilePicture(imageFile);
        }
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process image: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(creatorProfileProvider);
    final isCreator = ref.watch(userRoleProvider) == 'creator';
    final isUploading = ref.watch(profileUpdateProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(height: 200, decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1))),
          SafeArea(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (profile) {
                return Animate(
                  effects: const [FadeEffect(duration: Duration(milliseconds: 600), curve: Curves.easeOut), SlideEffect(begin: Offset(0, 0.1))],
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: _buildProfileHeader(context, ref, profile, isCreator, isUploading)
                        ),
                        const SizedBox(height: 24),
                        _buildSocialLinks(profile.socialLinks, theme),
                        const SizedBox(height: 24),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _buildAboutMeCard(profile.aboutMe, theme)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isCreator)
            Positioned(
              top: kToolbarHeight - 10,
              right: 16,
              child: Animate(
                delay: const Duration(milliseconds: 500),
                effects: const [ScaleEffect()],
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: theme.cardColor),
                  icon: Icon(Icons.edit_note_outlined, color: theme.colorScheme.secondary),
                  onPressed: () {
                    final profileData = ref.read(creatorProfileProvider).value;
                    if (profileData != null) {
                      _showEditProfileSheet(context, ref, profileData);
                    }
                  },
                  tooltip: 'Edit Profile Details',
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, CreatorProfile profile, bool isCreator, bool isUploading) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            SizedBox(
              width: 120,
              height: 150,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                child: isUploading
                    ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                    : profile.photoUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: profile.photoUrl, fit: BoxFit.cover, placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.person, size: 60))
                    : Icon(Icons.person, size: 60, color: theme.colorScheme.secondary),
              ),
            ),
            if (isCreator)
              Positioned(
                bottom: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondary,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () => _updateCreatorImage(context, ref),
                    tooltip: 'Change Profile Picture',
                  ),
                ),
              )
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Digital Artist & Creator', style: GoogleFonts.lato(fontSize: 16, color: theme.textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ],
    ).animate().slideX(begin: -0.2, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  Widget _buildSocialLinks(List<SocialLink> links, ThemeData theme) {
    if (links.isEmpty) return const SizedBox(height: 30);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: AnimateList(
          interval: const Duration(milliseconds: 80),
          effects: const [FadeEffect(duration: Duration(milliseconds: 300)), ScaleEffect(curve: Curves.easeOut)],
          children: links.map((link) => Tooltip(
            message: link.name,
            child: InkWell(
              onTap: () => _launchURL(link.url),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: theme.cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
                child: Center(child: FaIcon(_getIconForName(link.icon), color: theme.textTheme.bodyMedium?.color)),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutMeCard(String aboutMe, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About Me', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Text(
              aboutMe.isEmpty ? 'Tap the edit icon to tell everyone your story!' : aboutMe,
              style: GoogleFonts.lato(fontSize: 16, height: 1.6, color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileSheet extends ConsumerStatefulWidget {
  final CreatorProfile profile;
  const EditProfileSheet({super.key, required this.profile});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _aboutMeController;
  late final TextEditingController _whatsappController;
  late List<SocialLink> _links;

  @override
  void initState() {
    super.initState();
    _aboutMeController = TextEditingController(text: widget.profile.aboutMe);
    _whatsappController = TextEditingController(text: widget.profile.whatsappNumber);
    _links = List<SocialLink>.from(widget.profile.socialLinks.map((link) => SocialLink(name: link.name, url: link.url, icon: link.icon)));
  }

  void _saveChanges() {
    final firestoreService = ref.read(firestoreServiceProvider);
    firestoreService.updateAboutMe(_aboutMeController.text);
    firestoreService.updateWhatsappNumber(_whatsappController.text.trim());
    firestoreService.updateSocialLinks(_links);
    Navigator.of(context).pop();
  }

  void _showLinkDialog({SocialLink? existingLink, int? index}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingLink?.name);
    final urlController = TextEditingController(text: existingLink?.url);
    String selectedIcon = existingLink?.icon ?? supportedIcons.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingLink == null ? 'Add New Link' : 'Edit Link'),
              contentPadding: const EdgeInsets.all(20),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                        hintText: 'e.g., Instagram',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'URL or Email Address',
                        hintText: 'e.g., instagram.com/my_handle',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>.search(
                      hintText: 'Select Icon',
                      initialItem: selectedIcon,
                      items: supportedIcons,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedIcon = value);
                        }
                      },
                      decoration: CustomDropdownDecoration(
                        closedBorder: Border.all(color: Theme.of(context).dividerColor),
                        closedBorderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newLink = SocialLink(name: nameController.text, url: urlController.text, icon: selectedIcon);
                      setState(() {
                        if (index != null) {
                          _links[index] = newLink;
                        } else {
                          _links.add(newLink);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextField(controller: _aboutMeController, maxLines: 5, decoration: const InputDecoration(labelText: 'About Me', border: OutlineInputBorder(), alignLabelWithHint: true)),
            const SizedBox(height: 16),
            TextField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                  labelText: 'WhatsApp Order Number',
                  hintText: '+911234567890',
                  border: OutlineInputBorder()
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            const Text('Social Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (_links.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No social links yet. Add one below!')),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _links.length,
              itemBuilder: (context, index){
                final link = _links[index];
                return ListTile(
                  leading: FaIcon(_getIconForName(link.icon)),
                  title: Text(link.name),
                  subtitle: Text(link.url, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showLinkDialog(existingLink: link, index: index)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _links.removeAt(index))),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Link'),
              onPressed: () => _showLinkDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Save All Changes'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}