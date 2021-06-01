import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tapemobileapp/app/routing_constants.dart';
import 'package:tapemobileapp/ui/views/authenticate_view.dart';
import 'package:tapemobileapp/ui/views/chatpage_view.dart';
import 'package:tapemobileapp/ui/views/home_view.dart';
import 'package:tapemobileapp/ui/views/onboarding_view.dart';
import 'package:tapemobileapp/ui/views/profile_view.dart';
import 'package:tapemobileapp/ui/views/startup_view.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case StartupViewRoute:
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) => StartupView());
    case AuthenticationViewRoute:
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) => AuthenticationView());
    case HomeViewRoute:
      Map<String, dynamic> arguments =
          settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) =>
              HomeView(arguments['userUID'], arguments['phoneNumber']));
    case ProfileViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) =>
              ProfileView(arguments['downloadURL'], arguments['displayName']));
    case OnboardingViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) =>
              OnboardingView(arguments['userUID'], arguments['phoneNumber']));
    case ChatViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) =>
              ChatPageView(arguments['yourUID'], arguments['yourName']));
    default:
      return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
          ),
          builder: (context) => StartupView());
  }
}
