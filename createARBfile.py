import json
import os
import google.generativeai as genai
from dotenv import load_dotenv
import time
inspirationalQuotes = [
      "מה יעזור לי כעת, גם צעדים קטנים זאת התקדמות",
      "יש בי חוזקות",
      "בעבר כבר התמודדתי עם אתגרים",
      "מצב הרוח משתנה כמו מזג האוויר שאינו קבוע",
      "רגשות חולפים ומשתנים",
      "אני מסוגל",
      "יש לי כוחות",
      "אני לומד להירגע",
      "אחרי הירידות באות העליות",
      "זה בסדר לבכות",
      "תודה על היש",
      "קח רגע לחייך",
      "לזכור לנשום",
      "שגרה מייצרת יציבות",
      "תנועה מוציאה מיקפאון",
      "זה בסדר לבקש עזרה",
      "זה בסדר לא להיות בסדר",
      "שמור על הקצב שנכון לך",
      "מה נותן לך כוח להמשיך?"
    ]
thanksList = [
     "תודה שיש לי רגעים קלים יותר",
      "תודה על ארוחה טובה",
      "תודה שהצלחתי להתאמן",
      "תודה על שיחה טובה",
      "תודה שישנתי טוב",
      "תודה שהצלחתי",
      "תודה על בילוי עם",
      "תודה על מזג האוויר",
      "תודה שיש לי בית",
      "תודה על בריאות טובה",
      "תודה על משפחה",
      "תודה על חברים"
    ]
traitsList =  [
      "אני יודע לבקש עזרה",
      "אני חברותי",
      "אני חבר טוב",
      "אני מוכן להשקיע",
      "אני יצירתי",
      "אני מסוגל",
      "יש לי כוחות",
      "אני יודע לנהוג",
      "אני פתוח להתנסויות",
      "יש לי כוח התמדה וסבל",
      "אני סבלני",
      "אני ספורטיבי",
      "אני מסוגל",
      "אני טוב בארגון",
      "אני יודע לנגן",
      "אני יודע לבשל",
      "אני אבא טוב",
      "אני חזק",
      "אני חכם",
      "אני יפה",
      "אני מצחיק"
    ]
difficultEventsList =  [
      "צפייה בחדשות",
      "מתח עם הקרובים לי",
      "ריבים או וויכוחים מרובים",
      "בעבר כבר התמודדתי עם אתגרים",
      "עוול, אי צדק וחוסר הגינות",
      "חוסר תעסוקה",
      "אובדן",
      "פיטורין, אבטלה",
      "עומס יתר",
      "תחושה של מחסור כלכלי",
      "לחץ, ריבוי משימות",
      "דברים לא גמורים",
      "תזונה לא סדירה",
      "מלחמה",
      "סגר",
      "מחסור בשינה",
      "מוות של קרובים",
      "אובדן של יציבות ושגרה",
      "כשאין לי זמן להוציא אנרגיה ואגרסיות",
      "עומס גירויים"
      "חוסר וודאות ומעברים"
    ]
feelBetterList =[
      "מיינדפולנס",
      "זמן זוגי/חברתי קבוע בשבוע",
      "רשימת חוזקות ומעלות",
      "יומן הכרת תודה",
      "להגיד מתי יש לי יכולת להקשיב",
      "להאט ולהשתדל לא להעמיס עלי יותר מידי",
      "להתנתק ממשימות היום יום וממסכים",
      "לראות אור שמש",
      "לצאת לטבע",
      "מנוחה",
      "זמן שקט לעצמי",
      "לצחצח שיניים כדי לקבל טעם רענן בפה",
      "או לקחת מסטיק",
      "לקבל חיבוק ממישהו שאני סומך עליו",
      "לומר לעצמי: 'אני חשוב/ משמעותי / בעל ערך'",
      "'יש אנשים שאוהבים אותי'",
      "להתמקד בנשימה / בתחושות הגופניות",
      "לקחת הפסקה על ידי שינוי המיקום שלי (למשל, לעבור לחדר אחר בבית)",
      "לצאת להליכה קצרה בחוץ",
      "לצאת לנשום קצת אוויר צח (מחוץ לבית או אפילו מהמרפסת)",
      "לצפות בקליפים"]
makeSaferList = [
      "שיעזרו לי עם פרוייקטים משותפים שנותנים משמעות",
      "לברר מה קורה איתי ולחשוב איתי על דרך ההתמודדות",
      "שיזמינו אותי לעשייה משותפת",
      "שיבקרו אותי",
      "שיזמינו אותי לנגינה או משחק",
      "שיזמינו אותי לפעילות משותפת",
      "שיעודדו אותי לישון מספיק",
      "לא להישאר לבד",
      "שיזמינו אותי לארוחה",
      "לקבל אוכל מזין",
      "לבקש ממישהו שאני סומכ.ת עליו להישאר איתי",
      "שיזמינו אותי להליכה או טיול או לפעילות גופנית",
      "להימנע ממקומות שגורמים לי להרגיש לא בטוח",
      "להשאיר אצלי כמות קטנה בלבד של התרופות שלי",
      "ואת השאר להפקיד בידי מישהו שאני סומכת עליו",
      "לבקש ממישהו אחר להרחיק ממני דברים שעלולים לשמש אותי לפגוע בעצמי",
      "שישאלו אותי"
    ]
distractionsList =  [
      "מחשבות אובדניות",
      "ביטחון עצמי נמוך",
      "תחושה שלא אכפת ממני",
      "רצון להתחפר ולהתחבא או להיעלם",
      "עייפות קשה",
      "ירידה בתפקוד",
      "חוסר או ירידה בכוחות",
      "חרדות",
      "מיניות מופחתת",
      "אפאטיות או אדישות",
      "רגישות יתר",
      "האשמה עצמית",
      "פזרנות והעלאת מינון הקניות",
      "הזנחה עצמית",
      "ביטחון יתר",
      "לעשות את המינימום של המינימום - וגם זה במאמץ רב",
      "תפקוד ירוד",
      "מוח רץ",
      "מחשבות מתרוצצות ומהירות",
      "חוסר ביטחון",
      "הססנות",
      "מחשבות איטיות ומבולבלות",
      "מוחצנות מוגברת",
      "השתבללות",
      "התכנסות",
      "הסתגרות",
      "מילוי כל חלל הזמן",
      "חשש מזמן לבד",
      "חשש מריק",
      "שימוש רב במדיות שונות",
      "יותר כאבי ראש",
      "תיאבון יתר",
      "שינה לא סדירה",
      "נדודי שינה או שינה מעוטה",
    ]

load_dotenv(dotenv_path='D:/Git/Mazilon/.env')
genai.configure(api_key=os.environ["GEMINI_API_KEY"])

# Create the model
generation_config = {
  "temperature": 1,
  "top_p": 0.95,
  "top_k": 40,
  "max_output_tokens": 8192,
  "response_mime_type": "application/json",
}


def sendToGemini (text):
    model = genai.GenerativeModel(
    model_name="gemini-1.5-flash-8b",
    generation_config=generation_config,
    system_instruction="Your job is given a sentence in Hebrew, to identify the gendered terms and return a json-like object with a corresponding sentence for each of the following genders: male, female,non binary. Also, in the json object there should be an \"english\" field with the translated sentence. If there are no gendered words, return 3 identical sentences, and the english translation of it in the json like object. You sould be consistent and always use the \".\" symbol for the nonbinary word.\nexamples:\noriginal input: זה מה שאני אומר\nexpected output: { male: \"זה מה שאני אומר\", female: \"זה מה שאני אומרת\", nonbinary:\"זה מה שאני אומר.ת\", english:\"That is what I'm saying\"}\noriginal input: שגרה מייצרת יציבות\nexpected output: { male: \"שגרה מייצרת יציבות\", female: \"שגרה מייצרת יציבות\", nonbinary:\"שגרה מייצרת יציבות\", english:\"Routine creates stability\"}",
    )
    chat_session = model.start_chat(
        
    history=[
        {
        "role": "user",
        "parts": [
            "אני מסוגלת",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"אני מסוגל\",\n  \"female\": \"אני מסוגלת\",\n  \"nonbinary\": \"אני מסוגל.ת\"\n}\n```\n",
        ],
        },
        {
        "role": "user",
        "parts": [
            "זה בסדר לא להיות בסדר\n",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"זה בסדר לא להיות בסדר\",\n  \"female\": \"זה בסדר לא להיות בסדר\",\n  \"nonbinary\": \"זה בסדר לא להיות בסדר\",\n  \"english\": \"It's okay not to be okay\"\n}\n```\n",
        ],
        },
        {
        "role": "user",
        "parts": [
            "שמור על הקצב שנכון לך\n",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"שמור על הקצב שנכון לך\",\n  \"female\": \"שמרי על הקצב שנכון לך\",\n    \"nonbinary\": \"שמור.י על הקצב שנכון לך\",\n  \"english\": \"Keep the pace that is right for you\"\n}\n```\n",
        ],
        },
        {
        "role": "user",
        "parts": [
            "קח.י רגע לחייך",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"קח רגע לחייך\",\n  \"female\": \"קחי רגע לחייך\",\n  \"nonbinary\": \"קח.י רגע לחייך\",\n  \"english\": \"Take a moment to smile\"\n}\n```\n",
        ],
        },
        {
        "role": "user",
        "parts": [
            "אני לומד להירגע",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"אני לומד להירגע\",\n  \"female\": \"אני לומדת להירגע\",\n  \"nonbinary\": \"אני לומד.ת להירגע\",\n  \"english\": \"I'm learning to relax\"\n}\n```\n",
        ],
        },
        {
        "role": "user",
        "parts": [
            "תנועה מוציאה מיקפאון",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"תנועה מוציאה מיקפאון\",\n  \"female\": \"תנועה מוציאה מיקפאון\",\n  \"nonbinary\": \"תנועה מוציאה מיקפאון\",\n  \"english\": \"Movement releases tension\"\n}\n```\n",
        ],
        },
        {
        "role": "user",
        "parts": [
            "שמור על הקצב שנכון לך",
        ],
        },
        {
        "role": "model",
        "parts": [
            "```json\n{\n  \"male\": \"שמור על הקצב שנכון לך\",\n  \"female\": \"שמרי על הקצב שנכון לך\",\n  \"nonbinary\": \"שמור/י על הקצב שנכון לך\",\n  \"english\": \"Keep the pace that is right for you\"\n}\n```\n",
        ],
        },
    ]


    )

    response = chat_session.send_message({"parts": [{"text": text}]})
    return response 



def createARBfile (json,name):
    arbsentenceHeb= f"""\"{name}\":\"{{gender,select,male{{{json["male"]}}} female{{{json["female"]}}} other{{{json["nonbinary"]}}}}}\","""
    arbsentenceEng= f"""\"{name}\":\"{{gender,select,male{{{json["english"]}}} female{{{json["english"]}}} other{{{json["english"]}}}}}\",
   \"@{name}\": {{ 
   \"description\": \"\"
    }},"""
    return arbsentenceHeb.strip(), arbsentenceEng.strip()

def append_to_arb_file(file_path, content):
    with open(file_path, 'a', encoding='utf-8') as file:
        file.write(content + '\n')
if __name__ == "__main__":
   theList= {
        "name":"difficultEventsList",  
   }
   theList["list"]=globals()[theList["name"]],
   b=theList["list"]
   print( b[0])
   
   for index,text in enumerate(b[0]):

        print("started again",index)
        x = sendToGemini(text)
        print("got response")
        print(f"Response Text: {x.parts[0].text}")
        parsed_response = json.loads(x.parts[0].text.encode('utf-8'))
        arbsentenceHeb, arbsentenceEng = createARBfile(parsed_response, f"{theList["name"]}No{index}")
        append_to_arb_file('D:/Git/Mazilon/app_he.arb', arbsentenceHeb)
        append_to_arb_file('D:/Git/Mazilon/app_en.arb', arbsentenceEng)
        time.sleep(4)
    