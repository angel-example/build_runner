import 'package:angel_framework/angel_framework.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:angel_static/angel_static.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'pretty_logging.dart';

main() async {
  var app = new Angel();
  app.logger = new Logger.detached('angel')..onRecord.listen(prettyLog);

  if (!app.isProduction) {
    var applications = <BuilderApplication>[
      apply(
        'build_compilers',
        'ddc',
        [
          (_) => new ModuleBuilder(),
          (_) => new UnlinkedSummaryBuilder(),
          (_) => new LinkedSummaryBuilder(),
          (_) => new DevCompilerBuilder(),
        ],
        toAllPackages(),
        isOptional: true,
      ),
      applyToRoot(
        new DevCompilerBootstrapBuilder(),
        inputs: const ['web/main.dart'],
      ),
    ];

    var buildActions = createBuildActions(
      new PackageGraph.forThisPackage(),
      applications,
    );

    var serveHandler = await watch(
      buildActions,
      onLog: prettyLog,
      deleteFilesByDefault: true,
      enableLowResourcesMode: true,
      writeToCache: true,
    );

    app.use(embedShelf(serveHandler.handlerFor('web')));

    var vDir = new VirtualDirectory(app, const LocalFileSystem());
    app.use(vDir.handleRequest);
  }

  var server = await app.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
