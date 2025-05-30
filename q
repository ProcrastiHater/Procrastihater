[1mdiff --git a/lib/main.dart b/lib/main.dart[m
[1mindex 301b2fe..5e4c021 100644[m
[1m--- a/lib/main.dart[m
[1m+++ b/lib/main.dart[m
[36m@@ -100,6 +100,7 @@[m [mclass ProcrastiHater extends StatelessWidget {[m
   Widget build(BuildContext context) {[m
     double? screenHeight = MediaQuery.of(context).size.height;[m
     return MaterialApp([m
[32m+[m[32m      debugShowCheckedModeBanner: false,[m
       theme: ThemeData([m
         //brightness: Brightness.dark,[m
         scaffoldBackgroundColor: darkBlue,[m
