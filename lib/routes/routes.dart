import 'package:flutter/material.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/pages/estoque_page.dart';
import 'package:orama_admin/pages/formulario_page.dart';
import 'package:orama_admin/pages/relatorios_page.dart';
import 'package:orama_admin/pages/reposicao_add_page';
import 'package:orama_admin/pages/reposicao_page.dart';
import 'package:orama_admin/pages/sabores_admin_page.dart';
import 'package:orama_admin/pages/splash_page.dart';

class RouteName {
  static const splash = "/";
  static const admin_page = "/home";
  static const sabores_admin_page = "/sabores_admin_page";
  static const estoque_admin_page = "/estoque_admin_page";
  static const relatorios_sorvete_page = "/relatorios_sorvete_page";
  static const relatorios = "/relatorios";
  static const reposicao = "/reposicao";
  static const reposicao_add = "/reposicao_add";
  static const formulario = "/formulario";
}

class Routes {
  Routes._();
  static final routes = {
    RouteName.splash: (BuildContext context) {
      return SplashScreen();
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
      return ReposicaoPage(
        nome: '',
        data: '',
        reportData: {},
        city: '',
        loja: '',
      );
    },
    RouteName.reposicao_add: (BuildContext context) {
      return ReposicaoAddPage();
    },
    RouteName.formulario: (BuildContext context) {
      return FormularioPage(
        nome: '',
        data: '',
        reportData: {},
        city: '',
        loja: '',
      );
    },
  };
}
