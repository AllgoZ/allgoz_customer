import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialService {
  TutorialCoachMark? tutorialCoachMark;

  Future<void> showTutorialIfNeeded({
    required BuildContext context,
    required GlobalKey videoIconKey,
    required VoidCallback onTutorialComplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('tutorial_shown') ?? false;

    if (isTutorialShown) {
      onTutorialComplete();
      return;
    }

    List<TargetFocus> targets = [
      TargetFocus(
        identify: "videoIcon",
        keyTarget: videoIconKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tap here to view a quick video guide",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    tutorialCoachMark?.skip();
                  },
                  child: const Text("Skip"),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,

      // ✅ FIXED: Explicitly define return type as void
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('tutorial_shown', true);
          onTutorialComplete();
        });
        return true; // ✅ Required return
      },
      onFinish: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('tutorial_shown', true);
          onTutorialComplete();
        });
        return true; // ✅ Required return
      },


    )..show(context: context);
  }
}
