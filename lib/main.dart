import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bloc/tactics_board/tactics_board.dart';
import 'bloc/drawing/drawing_bloc.dart';
import 'config/supabase_config.dart';
import 'router.dart';
import 'tactics_board_page.dart';

/// Set to true by passing --dart-define=E2E_TEST=true at build/run time.
const bool _kE2eTest = bool.fromEnvironment('E2E_TEST');

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const TacticsBoardApp());
}

class TacticsBoardApp extends StatelessWidget {
  const TacticsBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // E2E bypass: skip auth gate entirely
    if (_kE2eTest) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TacticsBoardBloc()),
          BlocProvider(create: (_) => DrawingBloc()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tactics Board',
          theme: ThemeData(fontFamily: 'Raleway'),
          home: const TacticsBoardPage(),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TacticsBoardBloc()),
        BlocProvider(create: (_) => DrawingBloc()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Tactics Board',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          fontFamily: 'Raleway',
        ),
        routerConfig: router,
      ),
    );
  }
}
