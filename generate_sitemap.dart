import 'dart:io';

void main() {
  final siteUrl = 'https://tendanceofficiel.web.app';
  final routes = ['/', '/landing', '/home', '/login', '/signup']; // ajoute toutes tes routes ici

  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  for (var route in routes) {
    buffer.writeln('  <url>');
    buffer.writeln('    <loc>$siteUrl$route</loc>');
    buffer.writeln('    <priority>${route == '/' ? '1.0' : '0.8'}</priority>');
    buffer.writeln('  </url>');
  }

  buffer.writeln('</urlset>');

  File('web/sitemap.xml').writeAsStringSync(buffer.toString());
  print('Sitemap généré avec succès !');
}
