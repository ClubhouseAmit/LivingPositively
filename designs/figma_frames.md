# Figma Mockups & Screen Layout References

This file contains the specific Figma mockups and screen-by-screen widget layout trees parsed from figma_full_dump.json.

## 3. The 13 Main Frame Nodes & Layout Mappings

Below are the 13 core frames forming the application user journey. Each screen description maps back to its Figma Node ID, corresponding file in the codebase, and provides the compiled Flutter widget tree.

### Splash Screen (Android Large - 7)
*   **Figma ID:** `1660:2808`
*   **Target Code File:** [`lib/main.dart`](file:///Users/dafna/Documents/LivingPositively/lib/main.dart)
*   **Concept / Design:** The initial loading and splash screen of the application displaying the loading percentage.
*   **Key Extracted Elements:** Logo/Image placeholder, 'Done! 100% Loaded' status indicator text.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Splash Logo
        myImage('assets/images/logo.png', context, 0.4, 0.2),
        SizedBox(height: returnSizedBox(context, 20)),
        // Loading Status Text
        myAutoSizedText(
          'Done! 100% Loaded',
          TextStyle(
            color: AppColors.onSurface,
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
          TextAlign.center,
          16.0,
        ),
      ],
    ),
  ),
)
```

---

### Welcome Screen (Android Large - 2)
*   **Figma ID:** `1660:1264`
*   **Target Code File:** [`lib/pages/home.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/home.dart)
*   **Concept / Design:** The first user-facing screen introducing Metsilon/Mazilon and prompt to start the journey.
*   **Key Extracted Elements:** Metsilon title, supportive tagline, welcome illustration, and 'המשך' (Continue) primary button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        // Illustration Image
        myImage('assets/images/welcome.png', context, 0.6, 0.3),
        SizedBox(height: returnSizedBox(context, 30)),
        // Title: מה ששומר עליי (What keeps me safe)
        myAutoSizedText(
          'מה ששומר עליי',
          TextStyle(
            color: AppColors.onSurface,
            fontSize: 28.0,
            fontWeight: FontWeight.w500,
          ),
          TextAlign.center,
          28.0,
        ),
        SizedBox(height: returnSizedBox(context, 15)),
        // App Description Tagline
        myAutoSizedText(
          'מצילון - האפליקציה לשימור החיים ולשיפור איכות החיים!',
          TextStyle(
            color: AppColors.onSurface.withOpacity(0.8),
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
          ),
          TextAlign.center,
          18.0,
        ),
        SizedBox(height: returnSizedBox(context, 10)),
        myAutoSizedText(
          'איתנו תמצאו כלים מעולים לעזרה עצמית ותפתחו את החוסן הנפשי.',
          TextStyle(
            color: AppColors.neutralDark,
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
          ),
          TextAlign.center,
          14.0,
        ),
        Spacer(),
        // Continue Button
        ConfirmationButton(
          context,
          () => navigateToOnboarding(),
          'המשך',
          primaryButtonTextStyle(context),
        ),
      ],
    ),
  ),
)
```

---

### Onboarding - Name Input (Android Large - 28)
*   **Figma ID:** `1660:2278`
*   **Target Code File:** [`lib/initialForm/initialFormPage1.dart`](file:///Users/dafna/Documents/LivingPositively/lib/initialForm/initialFormPage1.dart)
*   **Concept / Design:** First step of user personalization asking for the user's name/nickname.
*   **Key Extracted Elements:** Back navigation button, step indicator, intro prompt, text input field for name, and 'המשך' (Continue) action button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  appBar: AppBar(
    leading: BackButton(color: AppColors.onSurface),
    elevation: 0,
    backgroundColor: Colors.transparent,
  ),
  body: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Screen Title: בוא/י נכיר
        myAutoSizedText(
          'בוא/י נכיר',
          TextStyle(
            color: AppColors.onSurface,
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
          ),
          TextAlign.right,
          24.0,
        ),
        SizedBox(height: returnSizedBox(context, 12)),
        // Instruction text
        myAutoSizedText(
          'מה השם שלך? (הרגישו בנוח לרשום כינוי במקום)',
          TextStyle(
            color: AppColors.neutralDark,
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
          TextAlign.right,
          16.0,
        ),
        SizedBox(height: returnSizedBox(context, 20)),
        // Name Text Field
        SizedBox(
          width: formFieldWidth(context),
          child: TextField(
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'הקלד/י שם או כינוי...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        Spacer(),
        ConfirmationButton(
          context,
          () => saveNameAndContinue(),
          'המשך',
          primaryButtonTextStyle(context),
        ),
        SizedBox(height: 20),
      ],
    ),
  ),
)
```

---

### Onboarding - Age Selection (Android Large - 17)
*   **Figma ID:** `1660:2242`
*   **Target Code File:** [`lib/initialForm/initialFormPage1.dart`](file:///Users/dafna/Documents/LivingPositively/lib/initialForm/initialFormPage1.dart)
*   **Concept / Design:** Second step of user personalization asking for the user's age group.
*   **Key Extracted Elements:** Back button, intro prompt, horizontal/vertical scrollable age group options (e.g. 18-30), and 'המשך' (Continue) primary button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  appBar: AppBar(
    leading: BackButton(color: AppColors.onSurface),
    elevation: 0,
    backgroundColor: Colors.transparent,
  ),
  body: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        myAutoSizedText(
          'בוא/י נכיר',
          TextStyle(
            color: AppColors.onSurface,
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
          ),
          TextAlign.right,
          24.0,
        ),
        SizedBox(height: returnSizedBox(context, 12)),
        myAutoSizedText(
          'מה הגיל שלך?',
          TextStyle(
            color: AppColors.neutralDark,
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
          TextAlign.right,
          16.0,
        ),
        SizedBox(height: returnSizedBox(context, 20)),
        // Age Selection Card Grid/List
        Expanded(
          child: ListView(
            children: [
              _buildAgeOptionCard(context, 'מתחת ל-18', false),
              _buildAgeOptionCard(context, '18-30', true), // Selected State
              _buildAgeOptionCard(context, '31-50', false),
              _buildAgeOptionCard(context, '51 ומעלה', false),
            ],
          ),
        ),
        ConfirmationButton(
          context,
          () => saveAgeAndContinue(),
          'המשך',
          primaryButtonTextStyle(context),
        ),
        SizedBox(height: 20),
      ],
    ),
  ),
)
```

---

### Safety Plan Intro (Android Large - 19)
*   **Figma ID:** `1660:2313`
*   **Target Code File:** [`lib/pages/PersonalPlan/myPlan.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/PersonalPlan/myPlan.dart)
*   **Concept / Design:** Introductory dashboard screen preparing the user to build their safety plan.
*   **Key Extracted Elements:** Title: 'תכנית הביטחון שלי', informational text explaining why it is important, 'מלאי עכשיו' (Fill now) primary button, and 'מלאי אחר כך' (Fill later) secondary button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Icon(Icons.security, size: 80, color: AppColors.primary),
        SizedBox(height: returnSizedBox(context, 20)),
        myAutoSizedText(
          'תכנית הביטחון שלי',
          TextStyle(
            color: AppColors.onSurface,
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
          ),
          TextAlign.center,
          24.0,
        ),
        SizedBox(height: returnSizedBox(context, 15)),
        myAutoSizedText(
          'בואי ניצור בקלות תכנית ביטחון אישית, שתיתן לך יד ברגעים שבהם הכל הופך ליותר מדי. הקדישי כמה דקות עכשיו, כדי שנוכל לעבור בקלות רגעי משבר עתידיים.',
          TextStyle(
            color: AppColors.onSurface.withOpacity(0.8),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
          TextAlign.center,
          16.0,
        ),
        Spacer(),
        // Fill now button
        ConfirmationButton(
          context,
          () => startSafetyPlan(),
          'מלאי עכשיו',
          primaryButtonTextStyle(context),
        ),
        SizedBox(height: returnSizedBox(context, 10)),
        // Fill later button
        CancelButton(
          context,
          () => skipSafetyPlan(),
          'מלאי אחר כך',
          TextStyle(color: AppColors.error),
        ),
      ],
    ),
  ),
)
```

---

### Safety Plan Step 1 - Coping Strategies (Android Large - 10)
*   **Figma ID:** `1660:2020`
*   **Target Code File:** [`lib/pages/PersonalPlan/myPlanPageFull.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/PersonalPlan/myPlanPageFull.dart)
*   **Concept / Design:** First step of the safety plan where users specify coping mechanisms to pass difficult moments.
*   **Key Extracted Elements:** Header with title: 'מה יעזור לי לעבור את הרגעים הכי קשים כרגע', descriptive paragraph, user input list/cards, suggestions card trigger, and progress indicator with 'המשיכי' (Continue) button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress indicator
          LinearProgressIndicator(value: 0.2, backgroundColor: AppColors.neutralLight, color: AppColors.primary),
          SizedBox(height: 20),
          // Heading text
          myAutoSizedText(
            'מה יעזור לי לעבור את הרגעים הכי קשים כרגע',
            TextStyle(color: AppColors.onSurface, fontSize: 18.0, fontWeight: FontWeight.w500),
            TextAlign.right,
            18.0,
          ),
          SizedBox(height: 10),
          myAutoSizedText(
            'כדי לעזור לי לעבור את הרגעים הקרובים, ולקנות לי קצת זמן כדי להשתמש בשאר התכנית, אני יכולה:',
            TextStyle(color: AppColors.neutralDark, fontSize: 14.0, fontWeight: FontWeight.w400),
            TextAlign.right,
            14.0,
          ),
          SizedBox(height: 20),
          // List of current items
          Expanded(
            child: ListView(
              children: [
                _buildStrategyInputCard(context, 'להתרכז בנשימות עמוקות 4-7-8'),
                _buildAddButton(context, 'לחצ.י כדי להוסיף אפשרויות המתאימות לך לתכנית הביטחון שלך'),
              ],
            ),
          ),
          // Suggestion box
          _buildSuggestionsAlert(context, 'אין לך רעיון? קבלי כמה הצעות'),
          SizedBox(height: 10),
          ConfirmationButton(
            context,
            () => goToStep2(),
            'המשיכי',
            primaryButtonTextStyle(context),
          ),
        ],
      ),
    ),
  ),
)
```

---

### Safety Plan Step 2 - Safe Environment (Android Large - 14)
*   **Figma ID:** `1660:2071`
*   **Target Code File:** [`lib/pages/PersonalPlan/myPlanPageFull.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/PersonalPlan/myPlanPageFull.dart)
*   **Concept / Design:** Second step where users note actions to make their physical environment safe.
*   **Key Extracted Elements:** Title: 'מה יעזור לי להפוך את המצב לבטוח יותר בשבילי', descriptive text, input list showing added safe env measures, and 'המשיכי' (Continue) button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: 0.4, backgroundColor: AppColors.neutralLight, color: AppColors.primary),
          SizedBox(height: 20),
          myAutoSizedText(
            'מה יעזור לי להפוך את המצב לבטוח יותר בשבילי',
            TextStyle(color: AppColors.onSurface, fontSize: 18.0, fontWeight: FontWeight.w500),
            TextAlign.right,
            18.0,
          ),
          SizedBox(height: 10),
          myAutoSizedText(
            'כדי לעזור לי להפוך את המצב והסביבה לבטוחים יותר עבורי, בטווח הקצר ובטווח הארוך יותר, כדאי לי:',
            TextStyle(color: AppColors.neutralDark, fontSize: 14.0, fontWeight: FontWeight.w400),
            TextAlign.right,
            14.0,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildStrategyInputCard(context, 'לבקש ממישהו אחר להרחיק ממני דברים שעלולים לשמש אותי לפגוע בעצמי'),
                _buildAddButton(context, 'לחצ.י כדי להוסיף אפשרויות'),
              ],
            ),
          ),
          ConfirmationButton(
            context,
            () => goToStep3(),
            'המשיכי',
            primaryButtonTextStyle(context),
          ),
        ],
      ),
    ),
  ),
)
```

---

### Safety Plan Step 3 - Calming/Mood Lifting (Android Large - 15)
*   **Figma ID:** `1660:2124`
*   **Target Code File:** [`lib/pages/PersonalPlan/myPlanPageFull.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/PersonalPlan/myPlanPageFull.dart)
*   **Concept / Design:** Third step where users write down sensory or physical techniques to calm distress.
*   **Key Extracted Elements:** Title: 'מה יעזור לי להירגע או לשפר את מצב הרוח שלי', lists of actions (e.g. 'להקשיב למוסיקה מרגיעה'), and 'המשיכי' (Continue) button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: 0.6, backgroundColor: AppColors.neutralLight, color: AppColors.primary),
          SizedBox(height: 20),
          myAutoSizedText(
            'מה יעזור לי להירגע או לשפר את מצב הרוח שלי',
            TextStyle(color: AppColors.onSurface, fontSize: 18.0, fontWeight: FontWeight.w500),
            TextAlign.right,
            18.0,
          ),
          SizedBox(height: 10),
          myAutoSizedText(
            'כדי לעזור לי לשפר את מצב הרוח, להירגע או להרגיש קצת פחות לחץ, אני יכולה:',
            TextStyle(color: AppColors.neutralDark, fontSize: 14.0, fontWeight: FontWeight.w400),
            TextAlign.right,
            14.0,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildStrategyInputCard(context, 'להקשיב למוסיקה מרגיעה'),
                _buildAddButton(context, 'לחצ.י כדי להוסיף אפשרויות'),
              ],
            ),
          ),
          ConfirmationButton(
            context,
            () => goToStep4(),
            'המשיכי',
            primaryButtonTextStyle(context),
          ),
        ],
      ),
    ),
  ),
)
```

---

### Safety Plan Step 4 - Distraction/Activities (Android Large - 16)
*   **Figma ID:** `1660:2182`
*   **Target Code File:** [`lib/pages/PersonalPlan/myPlanPageFull.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/PersonalPlan/myPlanPageFull.dart)
*   **Concept / Design:** Fourth step for listing distraction tasks to divert thoughts during heavy distress.
*   **Key Extracted Elements:** Title: 'מה יעזור לי להסיח את דעתי מהמצוקה וישמרו עליי עסוקה', list of items, and 'המשיכי' (Continue) button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: 0.75, backgroundColor: AppColors.neutralLight, color: AppColors.primary),
          SizedBox(height: 20),
          myAutoSizedText(
            'מה יעזור לי להסיח את דעתי מהמצוקה וישמרו עליי עסוקה',
            TextStyle(color: AppColors.onSurface, fontSize: 18.0, fontWeight: FontWeight.w500),
            TextAlign.right,
            18.0,
          ),
          SizedBox(height: 10),
          myAutoSizedText(
            'כדי להסיח את דעתי ולהעסיק אותי, אני יכולה:',
            TextStyle(color: AppColors.neutralDark, fontSize: 14.0, fontWeight: FontWeight.w400),
            TextAlign.right,
            14.0,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildStrategyInputCard(context, 'ליצור קשר עם מישהו'),
                _buildAddButton(context, 'לחצ.י כדי להוסיף אפשרויות'),
              ],
            ),
          ),
          ConfirmationButton(
            context,
            () => goToStep5(),
            'המשיכי',
            primaryButtonTextStyle(context),
          ),
        ],
      ),
    ),
  ),
)
```

---

### Safety Plan Step 5 - Support Network Contacts (Android Large - 21)
*   **Figma ID:** `1660:2342`
*   **Target Code File:** [`lib/pages/phone.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/phone.dart)
*   **Concept / Design:** Fifth step for importing/specifying family, friends, or therapist contact details.
*   **Key Extracted Elements:** Title: 'מי האנשים שתומכים בי, שאני יכולה לפנות אליהם במצוקה', contacts list layout, contacts permission trigger button, emergency hotlines section toggle, and 'המשיכי' (Continue) button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: 0.9, backgroundColor: AppColors.neutralLight, color: AppColors.primary),
          SizedBox(height: 20),
          myAutoSizedText(
            'מי האנשים שתומכים בי, שאני יכולה לפנות אליהם אם אני במצוקה/ חושבת לפגוע בעצמי',
            TextStyle(color: AppColors.onSurface, fontSize: 18.0, fontWeight: FontWeight.w500),
            TextAlign.right,
            18.0,
          ),
          SizedBox(height: 10),
          myAutoSizedText(
            'האנשים שאוהבים אותי ויעזרו לי לצלוח את הרגעים הקשים הם:',
            TextStyle(color: AppColors.neutralDark, fontSize: 14.0, fontWeight: FontWeight.w400),
            TextAlign.right,
            14.0,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                // Option to add from system contacts
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.contact_phone, color: AppColors.primary),
                    title: myText('הוסיף/י אנשים שיעזרו לך לצלוח את הרגעים הקשים מרשימת אנשי הקשר שלך', TextStyle(fontSize: 14.0), TextAlign.right),
                    onTap: () => importFromContacts(),
                  ),
                ),
              ],
            ),
          ),
          // Emergency Hotlines Trigger
          TextButton(
            onPressed: () => toggleEmergencyHotlines(),
            child: myText('מוקדים נוספים שאוכל לפנות אליהם במצוקה', TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold), TextAlign.center),
          ),
          SizedBox(height: 10),
          ConfirmationButton(
            context,
            () => finishSafetyPlan(),
            'המשיכי',
            primaryButtonTextStyle(context),
          ),
        ],
      ),
    ),
  ),
)
```

---

### Safety Plan Step 5 - Emergency Hotlines (Android Large - 32)
*   **Figma ID:** `1661:3270`
*   **Target Code File:** [`lib/pages/phone.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/phone.dart)
*   **Concept / Design:** A critical emergency/hotline directory with clickable quick-dial cards (ER, Mental Health support).
*   **Key Extracted Elements:** Hotlines list layout, phone number cards with dial triggers (e.g. Eran - 1201), quick dial action buttons, and 'המשיכי' (Continue) button.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: 0.95, backgroundColor: AppColors.neutralLight, color: AppColors.primary),
          SizedBox(height: 20),
          myAutoSizedText(
            'מוקדים נוספים שאוכל לפנות אליהם במצוקה',
            TextStyle(color: AppColors.onSurface, fontSize: 18.0, fontWeight: FontWeight.w500),
            TextAlign.center,
            18.0,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(Icons.phone, color: AppColors.success),
                    title: myText('ער"ן - עזרה ראשונה נפשית', TextStyle(fontWeight: FontWeight.bold), TextAlign.right),
                    subtitle: myText('טלפון- 1201 / מחו"ל- *2201 | שלוחה 5', TextStyle(color: AppColors.neutralDark), TextAlign.right),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => dialNumber('1201'),
                  ),
                ),
              ],
            ),
          ),
          ConfirmationButton(
            context,
            () => finishSafetyPlan(),
            'המשיכי',
            primaryButtonTextStyle(context),
          ),
        ],
      ),
    ),
  ),
)
```

---

### Safety Plan Completion (Android Large - 22)
*   **Figma ID:** `1660:1290`
*   **Target Code File:** [`lib/pages/thankYou.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/thankYou.dart)
*   **Concept / Design:** The celebration and wrap-up page loaded immediately after completing the safety plan steps.
*   **Key Extracted Elements:** Celebration text ('סיימתי! איזה כיף!'), details on next steps, share button to export as PDF/text, and 'סיימתי!' (I'm done!) primary button to access other wellness features.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Icon(Icons.check_circle_outline, size: 100, color: AppColors.success),
        SizedBox(height: returnSizedBox(context, 20)),
        myAutoSizedText(
          'איזה כיף!',
          TextStyle(
            color: AppColors.onSurface,
            fontSize: 28.0,
            fontWeight: FontWeight.w500,
          ),
          TextAlign.center,
          28.0,
        ),
        SizedBox(height: returnSizedBox(context, 15)),
        myAutoSizedText(
          'יצרת לך מדריך שיעזור לך ברגעי משבר! בוא/י ונכיר כלים נוספים לעזרה עצמית ולחוסן נפשי. עכשיו את יכולה לשתף את התוכנית עם הקרובים לך או להוריד אותה כקובץ.',
          TextStyle(
            color: AppColors.onSurface.withOpacity(0.8),
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
          TextAlign.center,
          16.0,
        ),
        Spacer(),
        // Share & Download Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: Icon(Icons.share, size: 30, color: AppColors.primary), onPressed: () => sharePlan()),
            IconButton(icon: Icon(Icons.picture_as_pdf, size: 30, color: AppColors.primary), onPressed: () => exportPdfPlan()),
          ],
        ),
        SizedBox(height: returnSizedBox(context, 20)),
        ConfirmationButton(
          context,
          () => navigateToHomeDashboard(),
          'סיימתי!',
          primaryButtonTextStyle(context),
        ),
      ],
    ),
  ),
)
```

---

### Gratitude List / Toda List (Android Large - 6)
*   **Figma ID:** `1660:1325`
*   **Target Code File:** [`lib/pages/journal.dart`](file:///Users/dafna/Documents/LivingPositively/lib/pages/journal.dart)
*   **Concept / Design:** The main listing and interaction interface for adding things that user feels grateful for today.
*   **Key Extracted Elements:** Header with 'היי אריאל', 'תודו ליסט' (Toda list title), scrollable list of added items (e.g. 'על המשפחה שלי', 'על שאני חזקה'), interactive add new entry card, and a bottom navbar.

#### Flutter Widget Tree:
```dart
Scaffold(
  backgroundColor: AppColors.pageBackground,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(Icons.menu), onPressed: () => openMenu()),
              myText('היי אריאל,', TextStyle(fontWeight: FontWeight.bold, fontSize: 18), TextAlign.right),
            ],
          ),
          SizedBox(height: 20),
          myAutoSizedText(
            'תודו ליסט',
            TextStyle(color: AppColors.onSurface, fontSize: 24.0, fontWeight: FontWeight.w500),
            TextAlign.right,
            24.0,
          ),
          SizedBox(height: 10),
          myAutoSizedText(
            'על מה אני מודה היום',
            TextStyle(color: AppColors.neutralDark, fontSize: 16.0),
            TextAlign.right,
            16.0,
          ),
          SizedBox(height: 20),
          // Scrollable Gratitude Items
          Expanded(
            child: ListView(
              children: [
                _buildGratitudeCard(context, 'על המשפחה שלי', '1'),
                _buildGratitudeCard(context, 'על שאני חזקה', '2'),
                _buildAddGratitudeInputCard(context),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
  bottomNavigationBar: BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'בית'),
      BottomNavigationBarItem(icon: Icon(Icons.book), label: 'התוכנית שלי'),
      BottomNavigationBarItem(icon: Icon(Icons.star), label: 'תודות'),
    ],
  ),
)
```

---