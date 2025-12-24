import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadApkButton extends StatefulWidget {
  @override
  _DownloadApkButtonState createState() => _DownloadApkButtonState();
}

class _DownloadApkButtonState extends State<DownloadApkButton> {
  String? downloadUrl;
  bool loading = false;

  Future<void> fetchDownloadUrl() async {
    setState(() => loading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('app-release.apk');
      final url = await ref.getDownloadURL(); // récupère le lien public (si règles le permettent)
      setState(() => downloadUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openUrl() async {
    final url = downloadUrl;
    if (url == null) {
      await fetchDownloadUrl();
      if (downloadUrl == null) return;
    }
    final uri = Uri.parse(downloadUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d\'ouvrir le lien.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : _openUrl,
      icon: Icon(Icons.download),
      label: Text(loading ? 'Chargement...' : "Télécharger l'APK"),
      style: ElevatedButton.styleFrom(
       
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
