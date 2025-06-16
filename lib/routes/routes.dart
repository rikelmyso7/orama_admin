import 'package:flutter/material.dart';
import 'package:orama_admin/auth/login_page.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/pages/estoque_page.dart';
import 'package:orama_admin/pages/loja/relatorios/Dataespecificoview.dart';
import 'package:orama_admin/pages/loja/relatorios/relatorios_page.dart';
import 'package:orama_admin/pages/loja/reposicao/reposicao_page.dart';
import 'package:orama_admin/pages/reposica_fabrica/view_fabrica_repo.dart';
import 'package:orama_admin/pages/sabores_admin_page.dart';
import 'package:orama_admin/pages/splash_page.dart';

class RouteName {
  static const splash = "/";
  static const login = "/login";
  static const admin_page = "/home";
  static const sabores_admin_page = "/sabores_admin_page";
  static const estoque_admin_page = "/estoque_admin_page";
  static const relatorios_sorvete_page = "/relatorios_sorvete_page";

  static const relatorios = "/relatorios";
  static const reposicao = "/reposicao";
  static const view_relatorio = "/view_relatorio";
  static const fabrica = "/fabrica";
}

class Routes {
  Routes._();
  static final routes = {
    RouteName.splash: (BuildContext context) {
      return SplashScreen();
    },
    RouteName.login: (BuildContext context) {
      return LoginPage();
    },

    RouteName.admin_page: (BuildContext context) {
      return AdminPage();
    },
    RouteName.sabores_admin_page: (BuildContext context) {
      return SaboresAdminPage(
        pdv: '',
      );
    },
    RouteName.estoque_admin_page: (BuildContext context) {
      return EstoqueAdminPage();
    },
    RouteName.relatorios_sorvete_page: (BuildContext context) {
      return EstoqueAdminPage();
    },
    RouteName.relatorios: (BuildContext context) {
      return RelatoriosPage();
    },
    RouteName.reposicao: (BuildContext context) {
      return ReposicaoPage();
    },
    RouteName.view_relatorio: (BuildContext context) {
      return Dataespecificoview(
        report: {},
      );
    },
    RouteName.fabrica: (BuildContext context) {
      return ViewFabricaRepo();
    },
  };
}
