import Foundation

/// One thing Papa can say, with an optional English gloss shown under it.
struct Line: Hashable, ExpressibleByStringLiteral {
    let text: String
    let english: String?

    init(_ text: String, _ english: String? = nil) {
        self.text = text
        self.english = english
    }

    init(stringLiteral value: String) {
        text = value
        english = nil
    }
}

struct LanguagePack {
    var welcome: Line
    var done: String
    var snooze: String
    /// What he says when Strict Papa has been ignored twice and the chappal flies.
    var chappal: Line
    var messages: [ReminderKind: [Tone: [Line]]]
}

/// Built-in messages. `{name}` becomes what Papa calls you, `{papa}` becomes his name.
/// English, Hinglish, Hindi, Tamil and Punjabi have all three tones.
/// The other languages ship one voice for now and fall back across tones.
enum MessageLibrary {
    static func messages(for kind: ReminderKind, language: Language, tone: Tone) -> [Line] {
        let pack = packs[language] ?? packs[.english]!
        if let byTone = pack.messages[kind] {
            if let exact = byTone[tone], !exact.isEmpty { return exact }
            if let any = byTone[.soft] ?? byTone.values.first(where: { !$0.isEmpty }) { return any }
        }
        return packs[.english]!.messages[kind]?[tone] ?? ["Have you eaten, {name}?"]
    }

    static func pack(_ language: Language) -> LanguagePack {
        packs[language] ?? packs[.english]!
    }

    static let packs: [Language: LanguagePack] = [
        .english: LanguagePack(
            welcome: "Hello {name}. I'm {papa}. From now on I will keep an eye on you. Eat on time.",
            done: "OK Dad",
            snooze: "10 min",
            chappal: Line("Twice I told you. Now the chappal will do the talking."),
            messages: [
                .meal: [
                    .strict: ["Have you eaten? Don't tell me 'later'. Go eat now.",
                              "Food first, laptop later. That's the rule in this house.",
                              "Skipping meals is not a personality trait, {name}. Eat."],
                    .soft: ["{name}, have you eaten? Take a proper break and eat something.",
                            "Whatever you're doing can wait ten minutes. Please eat.",
                            "Your mother asked me to check: did you eat?"],
                    .funny: ["Your stomach called. It is filing a complaint.",
                             "Even the WiFi takes a break. You should eat.",
                             "In my day we ate on time. Also we walked 10 km to school. Anyway, eat."],
                ],
                .water: [
                    .strict: ["Drink water. Right now. I'm waiting.", "How many glasses today? Exactly. Go drink."],
                    .soft: ["Have some water, {name}. Your body needs it.", "A glass of water, then back to work."],
                    .funny: ["Water. Not chai. Water.", "Your kidneys have sent me a letter. Drink water."],
                ],
                .move: [
                    .strict: ["Get up. Stretch. Sitting like this all day is not good.", "Five minute walk. Now. Don't make me come there."],
                    .soft: ["You've been sitting a long time. Stretch your legs a little.", "Walk around for a couple of minutes, {name}."],
                    .funny: ["Your chair has become your best friend. Time to make it jealous.", "Stand up. Touch your toes. Or at least try."],
                ],
                .callHome: [
                    .strict: ["When did you last call home? Call your mother today.", "Two minutes on the phone won't kill you. Call."],
                    .soft: ["Your mother would love to hear your voice. Give her a call.", "Call home today, {name}. Even a short call."],
                    .funny: ["Your mother has told the whole colony you don't call. Fix this.", "Free tip: one phone call home earns more blessings than any promotion."],
                ],
                .bedtime: [
                    .strict: ["It's late. Shut the laptop. Sleep.", "Nothing good comes from being awake at this hour. Go to bed."],
                    .soft: ["It's late, {name}. Rest now, tomorrow will take care of itself.", "Good night. Sleep well."],
                    .funny: ["Whatever you're watching, it'll still be there tomorrow. Sleep.", "Even the street dogs have gone quiet. Sleep."],
                ],
                .morning: [
                    .strict: ["Good morning. Up early is half the battle won. Get moving.", "Morning. Make your bed. Then everything else."],
                    .soft: ["Good morning, {name}. Have a good day. Eat a proper breakfast.", "A new day. Start it with some water and a stretch."],
                    .funny: ["Good morning! The sun came up without your permission. Follow its example.", "Rise and shine. Breakfast is not optional."],
                ],
                .lowBattery: [
                    .strict: ["Battery is low. Plug in the charger. How many times do I have to say it?", "Charge the laptop before it dies. And your phone."],
                    .soft: ["Battery is running low, {name}. Plug it in.", "Charger, {name}. Before it switches off."],
                    .funny: ["Your laptop is dying of thirst. Feed it electricity.", "Low battery. The charger is not decoration."],
                ],
                .focusBreak: [
                    .strict: ["Eyes off the screen for a minute. Look far away.", "Screen, screen, screen. Give your eyes a rest."],
                    .soft: ["Give your eyes a rest, {name}. Look out of the window a bit.", "Close your eyes for twenty seconds. Go on."],
                    .funny: ["Blink. Yes, you. You haven't blinked in ten minutes.", "Your eyes have applied for leave. Grant it."],
                ],
                .unplug: [
                    .strict: ["Battery is full. Take the charger out. Electricity is not free.",
                             "100 percent. Unplug it. Do you want the battery to swell?"],
                    .soft: ["It's fully charged, {name}. You can unplug it now.",
                             "The charger can come off now. The battery will thank you."],
                    .funny: ["It's at 100. Keeping it plugged in won't make it 110.",
                             "The laptop is full. Stop feeding it."],
                ],
                .trash: [
                    .strict: ["Your Trash is overflowing. Empty it. Now.",
                             "Is this a computer or a dumping ground? Clear the Trash."],
                    .soft: ["The Trash has piled up, {name}. Clear it out when you get a minute.",
                             "A quick clean-up: empty the Trash."],
                    .funny: ["The Trash has more files than your Documents folder. Empty it.",
                             "Rubbish everywhere. This is a home, not a dumping ground."],
                ],
            ]
        ),

        .hinglish: LanguagePack(
            welcome: Line("Namaste {name}. Main {papa} hoon. Ab se main dhyan rakhunga. Time pe khaana khao.",
                          "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "Theek hai Papa",
            snooze: "10 min baad",
            chappal: Line("Do baar bola. Ab chappal udegi.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [
                    .strict: [Line("Khaana khaya? 'Baad mein' nahi. Abhi jao.", "Have you eaten? Not 'later'. Go now."),
                              Line("Pehle khaana, phir laptop. Ghar ka rule hai.", "Food first, laptop later. House rule."),
                              Line("Khaana skip karna koi achievement nahi hai, {name}. Khao.", "Skipping meals is not an achievement, {name}. Eat.")],
                    .soft: [Line("{name}, khaana khaya? Thoda break lo aur kuch kha lo.", "{name}, have you eaten? Take a break and eat something."),
                            Line("Jo bhi kar rahe ho, das minute ruk sakta hai. Khaana kha lo.", "Whatever you're doing can wait ten minutes. Eat."),
                            Line("Mummy ne poochne bola hai: khaana khaya?", "Mummy asked me to check: did you eat?")],
                    .funny: [Line("Pet ne phone kiya tha. Complaint file kar raha hai.", "Your stomach called. It's filing a complaint."),
                             Line("WiFi bhi break leta hai. Tu bhi kha le.", "Even the WiFi takes a break. Go eat."),
                             Line("Hamare zamaane mein time pe khaate the. 10 km chal ke school bhi jaate the. Khair, khaana kha.", "In my day we ate on time. And walked 10 km to school. Anyway, eat.")],
                ],
                .water: [
                    .strict: [Line("Paani piyo. Abhi. Main wait kar raha hoon.", "Drink water. Now. I'm waiting."),
                              Line("Aaj kitne glass? Exactly. Jao piyo.", "How many glasses today? Exactly. Go drink.")],
                    .soft: [Line("Thoda paani pi lo {name}.", "Have some water, {name}."),
                            Line("Ek glass paani, phir kaam.", "One glass of water, then work.")],
                    .funny: [Line("Paani. Chai nahi. Paani.", "Water. Not chai. Water."),
                             Line("Kidney ne chitthi bheji hai. Paani piyo.", "Your kidneys sent a letter. Drink water.")],
                ],
                .move: [
                    .strict: [Line("Utho. Stretch karo. Saara din aise baithna theek nahi.", "Get up. Stretch. Sitting all day like this isn't good."),
                              Line("Paanch minute walk. Abhi. Mujhe wahan aana na pade.", "Five minute walk. Now. Don't make me come there.")],
                    .soft: [Line("Bahut der se baithe ho. Thoda tehel lo.", "You've been sitting a long time. Take a little walk."),
                            Line("Do minute chal phir lo {name}.", "Walk around for two minutes, {name}.")],
                    .funny: [Line("Kursi tera best friend ban gayi hai. Thoda jealous karo usko.", "Your chair is your best friend now. Make it jealous."),
                             Line("Khade ho jao. Pair ki ungliyan chhuo. Ya try toh karo.", "Stand up. Touch your toes. Or at least try.")],
                ],
                .callHome: [
                    .strict: [Line("Ghar pe last call kab kiya tha? Aaj Mummy ko phone karo.", "When did you last call home? Call Mummy today."),
                              Line("Do minute phone pe baat karne se kuch nahi hoga. Call karo.", "Two minutes on the phone won't hurt. Call.")],
                    .soft: [Line("Mummy ko tumhari awaaz sunke accha lagega. Ek call kar do.", "Mummy would love to hear your voice. Give her a call."),
                            Line("Aaj ghar phone karna {name}. Chhota sa hi sahi.", "Call home today, {name}. Even a short one.")],
                    .funny: [Line("Mummy ne poori colony ko bata diya hai ki tu phone nahi karta. Theek karo.", "Mummy has told the whole colony you don't call. Fix it."),
                             Line("Ek phone call ghar = promotion se zyada aashirwaad. Free tip.", "One call home earns more blessings than a promotion. Free tip.")],
                ],
                .bedtime: [
                    .strict: [Line("Raat ho gayi. Laptop band. So jao.", "It's night. Laptop off. Sleep."),
                              Line("Is time jaag ke kuch accha nahi hota. Jao so jao.", "Nothing good happens awake at this hour. Go to sleep.")],
                    .soft: [Line("Der ho gayi {name}. Ab aaram karo, kal dekh lenge.", "It's late, {name}. Rest now, we'll see tomorrow."),
                            Line("Shubh raatri. Accha so.", "Good night. Sleep well.")],
                    .funny: [Line("Jo bhi dekh rahe ho, kal bhi wahi rahega. So jao.", "Whatever you're watching will still be there tomorrow. Sleep."),
                             Line("Gali ke kutte bhi so gaye. Tu bhi so ja.", "Even the street dogs are asleep. You too.")],
                ],
                .morning: [
                    .strict: [Line("Good morning. Jaldi uthna aadhi jeet hai. Chalo shuru karo.", "Good morning. Waking early is half the battle. Get going."),
                              Line("Subah ho gayi. Bistar theek karo. Phir baaki sab.", "It's morning. Make your bed. Then everything else.")],
                    .soft: [Line("Good morning {name}. Din accha ho. Nashta zaroor karna.", "Good morning {name}. Have a good day. Do eat breakfast."),
                            Line("Naya din. Paani aur ek stretch se shuru karo.", "A new day. Start with water and a stretch.")],
                    .funny: [Line("Good morning! Sooraj bina permission nikal gaya. Tu bhi nikal.", "Good morning! The sun rose without permission. You rise too."),
                             Line("Utho utho. Nashta optional nahi hai.", "Up, up. Breakfast is not optional.")],
                ],
                .lowBattery: [
                    .strict: [Line("Battery kam hai. Charger lagao. Kitni baar bolna padega?", "Battery is low. Plug in the charger. How many times must I say it?"),
                              Line("Laptop band hone se pehle charge karo. Phone bhi.", "Charge the laptop before it dies. Phone too.")],
                    .soft: [Line("Battery kam ho rahi hai {name}. Charger laga do.", "Battery is getting low, {name}. Plug in the charger."),
                            Line("Charger, {name}. Band hone se pehle.", "Charger, {name}. Before it switches off.")],
                    .funny: [Line("Laptop pyaasa hai. Bijli pilao.", "The laptop is thirsty. Give it electricity."),
                             Line("Low battery. Charger decoration nahi hai.", "Low battery. The charger is not decoration.")],
                ],
                .focusBreak: [
                    .strict: [Line("Ek minute screen se nazar hatao. Door dekho.", "Eyes off the screen for a minute. Look far away."),
                              Line("Screen screen screen. Aankhon ko rest do.", "Screen, screen, screen. Rest your eyes.")],
                    .soft: [Line("Aankhon ko thoda rest do {name}. Khidki se bahar dekho.", "Rest your eyes a little, {name}. Look out of the window."),
                            Line("Bees second aankhein band karo. Chalo.", "Close your eyes for twenty seconds. Go on.")],
                    .funny: [Line("Palak jhapkao. Haan tu. Das minute se nahi jhapkayi.", "Blink. Yes, you. You haven't blinked in ten minutes."),
                             Line("Aankhon ne chhutti ki application di hai. Approve karo.", "Your eyes have applied for leave. Approve it.")],
                ],
                .unplug: [
                    .strict: [Line("Battery full hai. Charger nikaalo. Bijli free nahi aati.", "Battery is full. Take the charger out. Electricity isn't free."),
                             Line("100 percent ho gaya. Unplug karo. Battery phulani hai kya?", "It's at 100 percent. Unplug it. Do you want the battery to swell?")],
                    .soft: [Line("Full charge ho gaya {name}. Ab charger nikaal sakte ho.", "It's fully charged, {name}. You can unplug it now."),
                             Line("Charger ab hata do. Battery ki umar badhegi.", "Take the charger off now. The battery will live longer.")],
                    .funny: [Line("100 pe hai. Lagaye rakhne se 110 nahi hoga.", "It's at 100. Keeping it plugged in won't make it 110."),
                             Line("Laptop ka pet bhar gaya. Ab khilana band karo.", "The laptop's stomach is full. Stop feeding it.")],
                ],
                .trash: [
                    .strict: [Line("Trash bhar gaya hai. Khaali karo. Abhi.", "The Trash is full. Empty it. Now."),
                             Line("Yeh computer hai ya kabaad ki dukaan? Trash saaf karo.", "Is this a computer or a junk shop? Clear the Trash.")],
                    .soft: [Line("Trash mein bahut kuch jama ho gaya {name}. Time mile toh saaf kar do.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                             Line("Thodi safai: Trash khaali kar do.", "A little cleaning: empty the Trash.")],
                    .funny: [Line("Trash mein Documents se zyada files hain. Khaali karo.", "The Trash has more files than Documents. Empty it."),
                             Line("Kachra phailaya hua hai. Yeh ghar hai, dumping ground nahi.", "Rubbish everywhere. This is a home, not a dumping ground.")],
                ],
            ]
        ),

        .hindi: LanguagePack(
            welcome: Line("नमस्ते {name}। मैं {papa} हूँ। अब से मैं ध्यान रखूँगा। समय पर खाना खाओ।",
                          "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "ठीक है पापा",
            snooze: "10 मिनट बाद",
            chappal: Line("दो बार कहा। अब चप्पल उड़ेगी।", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [
                    .strict: [Line("खाना खाया? 'बाद में' नहीं। अभी जाओ।", "Have you eaten? Not 'later'. Go now."),
                              Line("पहले खाना, फिर लैपटॉप। घर का नियम है।", "Food first, laptop later. House rule."),
                              Line("खाना छोड़ना कोई कमाल नहीं है, {name}। खाओ।", "Skipping meals is no achievement, {name}. Eat.")],
                    .soft: [Line("{name}, खाना खाया? थोड़ा रुक कर कुछ खा लो।", "{name}, have you eaten? Pause and eat something."),
                            Line("जो भी कर रहे हो, दस मिनट रुक सकता है। खाना खा लो।", "Whatever you're doing can wait ten minutes. Eat."),
                            Line("मम्मी ने पूछने को कहा है: खाना खाया?", "Mummy asked me to check: did you eat?")],
                    .funny: [Line("पेट ने फ़ोन किया था। शिकायत दर्ज कर रहा है।", "Your stomach called. It's filing a complaint."),
                             Line("वाई-फ़ाई भी आराम करता है। तू भी खा ले।", "Even the WiFi rests. Go eat."),
                             Line("हमारे ज़माने में समय पर खाते थे। खैर, खाना खा।", "In my day we ate on time. Anyway, eat.")],
                ],
                .water: [
                    .strict: [Line("पानी पियो। अभी। मैं इंतज़ार कर रहा हूँ।", "Drink water. Now. I'm waiting."),
                              Line("आज कितने गिलास? यही। जाओ पियो।", "How many glasses today? Exactly. Go drink.")],
                    .soft: [Line("थोड़ा पानी पी लो {name}।", "Have some water, {name}."),
                            Line("एक गिलास पानी, फिर काम।", "One glass of water, then work.")],
                    .funny: [Line("पानी। चाय नहीं। पानी।", "Water. Not chai. Water."),
                             Line("किडनी ने चिट्ठी भेजी है। पानी पियो।", "Your kidneys sent a letter. Drink water.")],
                ],
                .move: [
                    .strict: [Line("उठो। स्ट्रेच करो। सारा दिन ऐसे बैठना ठीक नहीं।", "Get up. Stretch. Sitting all day isn't good."),
                              Line("पाँच मिनट टहलो। अभी।", "Five minute walk. Now.")],
                    .soft: [Line("बहुत देर से बैठे हो। थोड़ा टहल लो।", "You've been sitting a long time. Take a little walk."),
                            Line("दो मिनट चल फिर लो {name}।", "Walk around for two minutes, {name}.")],
                    .funny: [Line("कुर्सी तेरी सबसे अच्छी दोस्त बन गई है। थोड़ा जलाओ उसे।", "Your chair is your best friend now. Make it jealous."),
                             Line("खड़े हो जाओ। पैर की उँगलियाँ छुओ। या कोशिश तो करो।", "Stand up. Touch your toes. Or at least try.")],
                ],
                .callHome: [
                    .strict: [Line("घर पर आख़िरी बार फ़ोन कब किया था? आज मम्मी को फ़ोन करो।", "When did you last call home? Call Mummy today."),
                              Line("दो मिनट बात करने से कुछ नहीं होगा। फ़ोन करो।", "Two minutes of talking won't hurt. Call.")],
                    .soft: [Line("मम्मी को तुम्हारी आवाज़ सुनकर अच्छा लगेगा। एक फ़ोन कर दो।", "Mummy would love to hear your voice. Give her a call."),
                            Line("आज घर फ़ोन करना {name}। छोटा सा ही सही।", "Call home today, {name}. Even a short one.")],
                    .funny: [Line("मम्मी ने पूरी कॉलोनी को बता दिया है कि तू फ़ोन नहीं करता। ठीक करो।", "Mummy has told the whole colony you don't call. Fix it."),
                             Line("एक फ़ोन घर पर = प्रमोशन से ज़्यादा आशीर्वाद।", "One call home earns more blessings than a promotion.")],
                ],
                .bedtime: [
                    .strict: [Line("रात हो गई। लैपटॉप बंद। सो जाओ।", "It's night. Laptop off. Sleep."),
                              Line("इस समय जागकर कुछ अच्छा नहीं होता। जाओ सो जाओ।", "Nothing good happens awake at this hour. Go to sleep.")],
                    .soft: [Line("देर हो गई {name}। अब आराम करो, कल देख लेंगे।", "It's late, {name}. Rest now, we'll see tomorrow."),
                            Line("शुभ रात्रि। अच्छे से सो।", "Good night. Sleep well.")],
                    .funny: [Line("जो भी देख रहे हो, कल भी वही रहेगा। सो जाओ।", "Whatever you're watching will still be there tomorrow. Sleep."),
                             Line("गली के कुत्ते भी सो गए। तू भी सो जा।", "Even the street dogs are asleep. You too.")],
                ],
                .morning: [
                    .strict: [Line("सुप्रभात। जल्दी उठना आधी जीत है। चलो शुरू करो।", "Good morning. Waking early is half the battle. Get going."),
                              Line("सुबह हो गई। बिस्तर ठीक करो। फिर बाक़ी सब।", "It's morning. Make your bed. Then everything else.")],
                    .soft: [Line("सुप्रभात {name}। दिन अच्छा हो। नाश्ता ज़रूर करना।", "Good morning {name}. Have a good day. Do eat breakfast."),
                            Line("नया दिन। पानी और एक स्ट्रेच से शुरू करो।", "A new day. Start with water and a stretch.")],
                    .funny: [Line("सुप्रभात! सूरज बिना इजाज़त निकल गया। तू भी निकल।", "Good morning! The sun rose without permission. You rise too."),
                             Line("उठो उठो। नाश्ता वैकल्पिक नहीं है।", "Up, up. Breakfast is not optional.")],
                ],
                .lowBattery: [
                    .strict: [Line("बैटरी कम है। चार्जर लगाओ। कितनी बार बोलना पड़ेगा?", "Battery is low. Plug in the charger. How many times must I say it?"),
                              Line("लैपटॉप बंद होने से पहले चार्ज करो। फ़ोन भी।", "Charge the laptop before it dies. Phone too.")],
                    .soft: [Line("बैटरी कम हो रही है {name}। चार्जर लगा दो।", "Battery is getting low, {name}. Plug in the charger."),
                            Line("चार्जर, {name}। बंद होने से पहले।", "Charger, {name}. Before it switches off.")],
                    .funny: [Line("लैपटॉप प्यासा है। बिजली पिलाओ।", "The laptop is thirsty. Give it electricity."),
                             Line("बैटरी कम। चार्जर सजावट नहीं है।", "Low battery. The charger is not decoration.")],
                ],
                .focusBreak: [
                    .strict: [Line("एक मिनट स्क्रीन से नज़र हटाओ। दूर देखो।", "Eyes off the screen for a minute. Look far away."),
                              Line("स्क्रीन स्क्रीन स्क्रीन। आँखों को आराम दो।", "Screen, screen, screen. Rest your eyes.")],
                    .soft: [Line("आँखों को थोड़ा आराम दो {name}। खिड़की से बाहर देखो।", "Rest your eyes a little, {name}. Look out of the window."),
                            Line("बीस सेकंड आँखें बंद करो। चलो।", "Close your eyes for twenty seconds. Go on.")],
                    .funny: [Line("पलक झपकाओ। हाँ तू। दस मिनट से नहीं झपकाई।", "Blink. Yes, you. You haven't blinked in ten minutes."),
                             Line("आँखों ने छुट्टी की अर्ज़ी दी है। मंज़ूर करो।", "Your eyes have applied for leave. Approve it.")],
                ],
                .unplug: [
                    .strict: [Line("बैटरी फुल है। चार्जर निकालो। बिजली मुफ़्त नहीं आती।", "Battery is full. Take the charger out. Electricity isn't free."),
                             Line("सौ प्रतिशत हो गया। अनप्लग करो। बैटरी फुलानी है क्या?", "It's at 100 percent. Unplug it. Do you want the battery to swell?")],
                    .soft: [Line("पूरा चार्ज हो गया {name}। अब चार्जर निकाल सकते हो।", "It's fully charged, {name}. You can unplug it now."),
                             Line("चार्जर अब हटा दो। बैटरी की उम्र बढ़ेगी।", "Take the charger off now. The battery will live longer.")],
                    .funny: [Line("सौ पर है। लगाए रखने से एक सौ दस नहीं होगा।", "It's at 100. Keeping it plugged in won't make it 110."),
                             Line("लैपटॉप का पेट भर गया। अब खिलाना बंद करो।", "The laptop's stomach is full. Stop feeding it.")],
                ],
                .trash: [
                    .strict: [Line("ट्रैश भर गया है। खाली करो। अभी।", "The Trash is full. Empty it. Now."),
                             Line("यह कंप्यूटर है या कबाड़ की दुकान? ट्रैश साफ़ करो।", "Is this a computer or a junk shop? Clear the Trash.")],
                    .soft: [Line("ट्रैश में बहुत कुछ जमा हो गया {name}। समय मिले तो साफ़ कर दो।", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                             Line("थोड़ी सफ़ाई: ट्रैश खाली कर दो।", "A little cleaning: empty the Trash.")],
                    .funny: [Line("ट्रैश में Documents से ज़्यादा फ़ाइलें हैं। खाली करो।", "The Trash has more files than Documents. Empty it."),
                             Line("कचरा फैला हुआ है। यह घर है, डंपिंग ग्राउंड नहीं।", "Rubbish everywhere. This is a home, not a dumping ground.")],
                ],
            ]
        ),

        .tamil: LanguagePack(
            welcome: Line("வணக்கம் {name}. நான் {papa}. இனிமே நான் கவனிச்சுக்கறேன். நேரத்துக்கு சாப்பிடு.",
                          "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "சரி அப்பா",
            snooze: "10 நிமிஷம்",
            chappal: Line("ரெண்டு தடவை சொன்னேன். இப்போ செருப்பு பறக்கும்.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [
                    .strict: [Line("சாப்டியா? 'அப்புறம்' எல்லாம் வேண்டாம். இப்போ போய் சாப்பிடு.", "Have you eaten? No 'later'. Go eat now."),
                              Line("முதல்ல சாப்பாடு, அப்புறம் லேப்டாப். இது வீட்டு ரூல்.", "Food first, laptop later. House rule.")],
                    .soft: [Line("{name}, சாப்டியா? கொஞ்சம் ப்ரேக் எடுத்து சாப்பிடு.", "{name}, have you eaten? Take a break and eat."),
                            Line("அம்மா கேட்கச் சொன்னாங்க: சாப்டியா?", "Amma asked me to check: did you eat?")],
                    .funny: [Line("வயிறு எனக்கு போன் பண்ணுச்சு. கம்ப்ளெயிண்ட் கொடுக்குதாம்.", "Your stomach called me. It's filing a complaint."),
                             Line("வைஃபை கூட ரெஸ்ட் எடுக்குது. நீயும் சாப்பிடு.", "Even the WiFi rests. Go eat.")],
                ],
                .water: [
                    .strict: [Line("தண்ணி குடி. இப்பவே. நான் காத்திருக்கேன்.", "Drink water. Now. I'm waiting."),
                              Line("இன்னைக்கு எத்தனை கிளாஸ்? அதான். போய் குடி.", "How many glasses today? Exactly. Go drink.")],
                    .soft: [Line("கொஞ்சம் தண்ணி குடி {name}.", "Have some water, {name}."),
                            Line("ஒரு கிளாஸ் தண்ணி, அப்புறம் வேலை.", "One glass of water, then work.")],
                    .funny: [Line("தண்ணி. டீ இல்ல. தண்ணி.", "Water. Not tea. Water."),
                             Line("கிட்னி லெட்டர் அனுப்பிருக்கு. தண்ணி குடி.", "Your kidneys sent a letter. Drink water.")],
                ],
                .move: [
                    .strict: [Line("எழுந்திரு. ஸ்ட்ரெச் பண்ணு. நாள் முழுக்க இப்படி உக்காந்திருக்கக் கூடாது.", "Get up. Stretch. You can't sit like this all day."),
                              Line("அஞ்சு நிமிஷம் நட. இப்பவே.", "Five minute walk. Now.")],
                    .soft: [Line("ரொம்ப நேரம் உக்காந்திருக்க. கொஞ்சம் நட {name}.", "You've been sitting a long time. Walk a bit, {name}."),
                            Line("ரெண்டு நிமிஷம் எழுந்து நடந்து வா.", "Get up and walk for two minutes.")],
                    .funny: [Line("சேர் உன் பெஸ்ட் ஃப்ரெண்ட் ஆயிடுச்சு. கொஞ்சம் பொறாமைப்படுத்து.", "Your chair is your best friend now. Make it jealous."),
                             Line("எழுந்து நில்லு. கால் விரலை தொடு. முயற்சியாவது பண்ணு.", "Stand up. Touch your toes. At least try.")],
                ],
                .callHome: [
                    .strict: [Line("வீட்டுக்கு கடைசியா எப்போ போன் பண்ணின? இன்னைக்கு அம்மாவுக்கு போன் பண்ணு.", "When did you last call home? Call Amma today."),
                              Line("ரெண்டு நிமிஷம் பேசினா ஒண்ணும் ஆகாது. போன் பண்ணு.", "Two minutes of talking won't hurt. Call.")],
                    .soft: [Line("அம்மா உன் குரல் கேட்டா சந்தோஷப்படுவா. ஒரு போன் பண்ணு.", "Amma would be happy to hear your voice. Give her a call."),
                            Line("இன்னைக்கு வீட்டுக்கு போன் பண்ணு {name}. சின்னதா இருந்தாலும் சரி.", "Call home today, {name}. Even a short one.")],
                    .funny: [Line("நீ போன் பண்ணல்லன்னு அம்மா தெரு முழுக்க சொல்லிட்டாங்க. சரி பண்ணு.", "Amma has told the whole street you don't call. Fix it."),
                             Line("ஒரு போன் கால் = ப்ரமோஷனை விட அதிக ஆசீர்வாதம். ஃப்ரீ டிப்.", "One call home earns more blessings than a promotion. Free tip.")],
                ],
                .bedtime: [
                    .strict: [Line("நேரம் ஆச்சு. லேப்டாப் மூடு. தூங்கு.", "It's late. Close the laptop. Sleep."),
                              Line("இந்த நேரத்துல முழிச்சிருந்து நல்லது எதுவும் வராது. போய் தூங்கு.", "Nothing good comes from being awake now. Go sleep.")],
                    .soft: [Line("லேட் ஆயிடுச்சு {name}. இப்போ ரெஸ்ட் எடு, நாளைக்கு பார்க்கலாம்.", "It's late, {name}. Rest now, we'll see tomorrow."),
                            Line("குட் நைட். நல்லா தூங்கு.", "Good night. Sleep well.")],
                    .funny: [Line("என்ன பார்த்துட்டு இருக்கியோ, அது நாளைக்கும் இருக்கும். தூங்கு.", "Whatever you're watching will still be there tomorrow. Sleep."),
                             Line("தெரு நாய்களும் தூங்கிடுச்சு. நீயும் தூங்கு.", "Even the street dogs are asleep. You too.")],
                ],
                .morning: [
                    .strict: [Line("காலை வணக்கம். சீக்கிரம் எழுந்திருப்பது பாதி வெற்றி. ஆரம்பி.", "Good morning. Waking early is half the battle. Begin."),
                              Line("விடிஞ்சிடுச்சு. படுக்கையை சரி பண்ணு. அப்புறம் மீதி.", "It's morning. Make your bed. Then the rest.")],
                    .soft: [Line("காலை வணக்கம் {name}. நல்ல நாள் ஆகட்டும். காலை சாப்பாடு கட்டாயம்.", "Good morning {name}. Have a good day. Breakfast is a must."),
                            Line("புது நாள். தண்ணி, ஒரு ஸ்ட்ரெச்சோட ஆரம்பி.", "A new day. Start with water and a stretch.")],
                    .funny: [Line("காலை வணக்கம்! சூரியன் உன் பர்மிஷன் இல்லாம வந்துடுச்சு. நீயும் வா.", "Good morning! The sun rose without your permission. You rise too."),
                             Line("எழுந்திரு. காலை சாப்பாடு ஆப்ஷனல் இல்ல.", "Get up. Breakfast is not optional.")],
                ],
                .lowBattery: [
                    .strict: [Line("பேட்டரி குறைவு. சார்ஜர் போடு. எத்தனை தடவை சொல்லணும்?", "Battery is low. Plug in the charger. How many times must I say it?"),
                              Line("லேப்டாப் ஆஃப் ஆகறதுக்கு முன்னாடி சார்ஜ் பண்ணு. போனும்.", "Charge the laptop before it dies. Phone too.")],
                    .soft: [Line("பேட்டரி குறைஞ்சுடுச்சு {name}. சார்ஜர் போடு.", "Battery is low, {name}. Plug in the charger."),
                            Line("சார்ஜர், {name}. ஆஃப் ஆகறதுக்கு முன்னாடி.", "Charger, {name}. Before it switches off.")],
                    .funny: [Line("லேப்டாப்புக்கு தாகம். கரண்ட் கொடு.", "The laptop is thirsty. Give it current."),
                             Line("லோ பேட்டரி. சார்ஜர் அலங்காரம் இல்ல.", "Low battery. The charger is not decoration.")],
                ],
                .focusBreak: [
                    .strict: [Line("ஒரு நிமிஷம் ஸ்க்ரீனை விட்டு தூரமா பாரு.", "Look away from the screen for a minute."),
                              Line("ஸ்க்ரீன் ஸ்க்ரீன் ஸ்க்ரீன். கண்ணுக்கு ரெஸ்ட் கொடு.", "Screen, screen, screen. Rest your eyes.")],
                    .soft: [Line("கண்ணுக்கு கொஞ்சம் ரெஸ்ட் கொடு {name}. ஜன்னல் வழியா பாரு.", "Rest your eyes a little, {name}. Look out of the window."),
                            Line("இருபது செகண்ட் கண்ணை மூடு.", "Close your eyes for twenty seconds.")],
                    .funny: [Line("கண்ணை சிமிட்டு. ஆமா நீதான். பத்து நிமிஷமா சிமிட்டல.", "Blink. Yes, you. You haven't blinked in ten minutes."),
                             Line("கண்ணு லீவ் கேட்டிருக்கு. கொடு.", "Your eyes have asked for leave. Grant it.")],
                ],
                .unplug: [
                    .strict: [Line("பேட்டரி ஃபுல் ஆயிடுச்சு. சார்ஜரை எடு. கரண்ட் இலவசம் இல்லை.", "Battery is full. Take the charger out. Electricity isn't free."),
                             Line("நூறு சதவீதம். அன்ப்ளக் பண்ணு. பேட்டரி வீங்க வேண்டுமா?", "It's at 100 percent. Unplug it. Do you want the battery to swell?")],
                    .soft: [Line("ஃபுல் சார்ஜ் ஆயிடுச்சு {name}. இப்போ சார்ஜரை எடுத்துடலாம்.", "It's fully charged, {name}. You can unplug it now."),
                             Line("சார்ஜரை இப்போ எடுத்துடு. பேட்டரி நீண்ட நாள் இருக்கும்.", "Take the charger off now. The battery will last longer.")],
                    .funny: [Line("நூறுல இருக்கு. போட்டு வெச்சா நூற்றுப்பத்து ஆகாது.", "It's at 100. Keeping it plugged in won't make it 110."),
                             Line("லேப்டாப்புக்கு வயிறு நிறைஞ்சிடுச்சு. இனி ஊட்டாதே.", "The laptop's stomach is full. Stop feeding it.")],
                ],
                .trash: [
                    .strict: [Line("டிராஷ் நிறைஞ்சிடுச்சு. காலி பண்ணு. இப்பவே.", "The Trash is full. Empty it. Now."),
                             Line("இது கம்ப்யூட்டரா இல்ல குப்பைக் கடையா? டிராஷை சுத்தம் பண்ணு.", "Is this a computer or a junk shop? Clear the Trash.")],
                    .soft: [Line("டிராஷ்ல நிறைய சேர்ந்திடுச்சு {name}. நேரம் இருந்தா சுத்தம் பண்ணு.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                             Line("சின்ன சுத்தம்: டிராஷை காலி பண்ணு.", "A little cleaning: empty the Trash.")],
                    .funny: [Line("Documents-ஐ விட டிராஷ்ல அதிக ஃபைல்ஸ் இருக்கு. காலி பண்ணு.", "The Trash has more files than Documents. Empty it."),
                             Line("குப்பை எல்லா இடத்துலயும். இது வீடு, குப்பைமேடு இல்ல.", "Rubbish everywhere. This is a home, not a dump.")],
                ],
            ]
        ),

        .punjabi: LanguagePack(
            welcome: Line("ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ {name}। ਮੈਂ {papa} ਹਾਂ। ਹੁਣ ਤੋਂ ਮੈਂ ਧਿਆਨ ਰੱਖਾਂਗਾ। ਵੇਲੇ ਸਿਰ ਰੋਟੀ ਖਾ।",
                          "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "ਠੀਕ ਹੈ ਪਾਪਾ",
            snooze: "10 ਮਿੰਟ",
            chappal: Line("ਦੋ ਵਾਰੀ ਕਿਹਾ। ਹੁਣ ਚੱਪਲ ਉੱਡੇਗੀ।", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [
                    .strict: [Line("ਰੋਟੀ ਖਾ ਲਈ? 'ਬਾਅਦ ਵਿੱਚ' ਨਹੀਂ। ਹੁਣੇ ਜਾ।", "Have you eaten? Not 'later'. Go now."),
                              Line("ਪਹਿਲਾਂ ਰੋਟੀ, ਫਿਰ ਲੈਪਟਾਪ। ਘਰ ਦਾ ਨਿਯਮ ਹੈ।", "Food first, laptop later. House rule.")],
                    .soft: [Line("{name}, ਰੋਟੀ ਖਾ ਲਈ? ਥੋੜ੍ਹਾ ਰੁਕ ਕੇ ਕੁਝ ਖਾ ਲੈ।", "{name}, have you eaten? Pause and eat something."),
                            Line("ਮੰਮੀ ਨੇ ਪੁੱਛਣ ਲਈ ਕਿਹਾ: ਰੋਟੀ ਖਾ ਲਈ?", "Mummy asked me to check: did you eat?")],
                    .funny: [Line("ਪੇਟ ਨੇ ਫ਼ੋਨ ਕੀਤਾ ਸੀ। ਸ਼ਿਕਾਇਤ ਕਰ ਰਿਹਾ ਹੈ।", "Your stomach called. It's complaining."),
                             Line("ਸਾਡੇ ਵੇਲੇ ਟਾਈਮ 'ਤੇ ਖਾਂਦੇ ਸੀ। ਚੱਲ, ਰੋਟੀ ਖਾ।", "In my day we ate on time. Go on, eat.")],
                ],
                .water: [
                    .strict: [Line("ਪਾਣੀ ਪੀ। ਹੁਣੇ। ਮੈਂ ਉਡੀਕ ਰਿਹਾ ਹਾਂ।", "Drink water. Now. I'm waiting."),
                              Line("ਅੱਜ ਕਿੰਨੇ ਗਲਾਸ? ਬਿਲਕੁਲ। ਜਾ ਕੇ ਪੀ।", "How many glasses today? Exactly. Go drink.")],
                    .soft: [Line("ਥੋੜ੍ਹਾ ਪਾਣੀ ਪੀ ਲੈ {name}।", "Have some water, {name}."),
                            Line("ਇੱਕ ਗਲਾਸ ਪਾਣੀ, ਫਿਰ ਕੰਮ।", "One glass of water, then work.")],
                    .funny: [Line("ਪਾਣੀ। ਚਾਹ ਨਹੀਂ। ਪਾਣੀ।", "Water. Not chai. Water."),
                             Line("ਗੁਰਦਿਆਂ ਨੇ ਚਿੱਠੀ ਭੇਜੀ ਹੈ। ਪਾਣੀ ਪੀ।", "Your kidneys sent a letter. Drink water.")],
                ],
                .move: [
                    .strict: [Line("ਉੱਠ। ਸਟ੍ਰੈੱਚ ਕਰ। ਸਾਰਾ ਦਿਨ ਇੰਝ ਬੈਠਣਾ ਠੀਕ ਨਹੀਂ।", "Get up. Stretch. Sitting all day isn't good."),
                              Line("ਪੰਜ ਮਿੰਟ ਤੁਰ। ਹੁਣੇ।", "Five minute walk. Now.")],
                    .soft: [Line("ਬਹੁਤ ਦੇਰ ਤੋਂ ਬੈਠਾ ਹੈਂ। ਥੋੜ੍ਹਾ ਤੁਰ ਫਿਰ ਲੈ {name}।", "You've been sitting a long time. Walk a bit, {name}."),
                            Line("ਦੋ ਮਿੰਟ ਉੱਠ ਕੇ ਤੁਰ।", "Get up and walk for two minutes.")],
                    .funny: [Line("ਕੁਰਸੀ ਤੇਰੀ ਬੈਸਟ ਫ੍ਰੈਂਡ ਬਣ ਗਈ ਹੈ। ਥੋੜ੍ਹਾ ਸਾੜ ਉਹਨੂੰ।", "Your chair is your best friend now. Make it jealous."),
                             Line("ਖੜ੍ਹਾ ਹੋ। ਪੈਰਾਂ ਦੀਆਂ ਉਂਗਲਾਂ ਛੂਹ। ਕੋਸ਼ਿਸ਼ ਤਾਂ ਕਰ।", "Stand up. Touch your toes. At least try.")],
                ],
                .callHome: [
                    .strict: [Line("ਘਰ ਆਖ਼ਰੀ ਵਾਰ ਫ਼ੋਨ ਕਦੋਂ ਕੀਤਾ ਸੀ? ਅੱਜ ਮੰਮੀ ਨੂੰ ਫ਼ੋਨ ਕਰ।", "When did you last call home? Call Mummy today."),
                              Line("ਦੋ ਮਿੰਟ ਗੱਲ ਕਰਨ ਨਾਲ ਕੁਝ ਨਹੀਂ ਹੁੰਦਾ। ਫ਼ੋਨ ਕਰ।", "Two minutes of talking won't hurt. Call.")],
                    .soft: [Line("ਮੰਮੀ ਨੂੰ ਤੇਰੀ ਆਵਾਜ਼ ਸੁਣ ਕੇ ਚੰਗਾ ਲੱਗੇਗਾ। ਇੱਕ ਫ਼ੋਨ ਕਰ ਦੇ।", "Mummy would love to hear your voice. Give her a call."),
                            Line("ਅੱਜ ਘਰ ਫ਼ੋਨ ਕਰਨਾ {name}। ਛੋਟਾ ਹੀ ਸਹੀ।", "Call home today, {name}. Even a short one.")],
                    .funny: [Line("ਮੰਮੀ ਨੇ ਸਾਰੀ ਕਲੋਨੀ ਨੂੰ ਦੱਸ ਦਿੱਤਾ ਕਿ ਤੂੰ ਫ਼ੋਨ ਨਹੀਂ ਕਰਦਾ। ਠੀਕ ਕਰ।", "Mummy has told the whole colony you don't call. Fix it."),
                             Line("ਇੱਕ ਫ਼ੋਨ ਘਰ = ਪ੍ਰਮੋਸ਼ਨ ਤੋਂ ਵੱਧ ਅਸੀਸਾਂ।", "One call home earns more blessings than a promotion.")],
                ],
                .bedtime: [
                    .strict: [Line("ਰਾਤ ਹੋ ਗਈ। ਲੈਪਟਾਪ ਬੰਦ। ਸੌਂ ਜਾ।", "It's night. Laptop off. Sleep."),
                              Line("ਇਸ ਵੇਲੇ ਜਾਗ ਕੇ ਕੁਝ ਚੰਗਾ ਨਹੀਂ ਹੁੰਦਾ। ਜਾ ਸੌਂ ਜਾ।", "Nothing good happens awake at this hour. Go to sleep.")],
                    .soft: [Line("ਦੇਰ ਹੋ ਗਈ {name}। ਹੁਣ ਆਰਾਮ ਕਰ, ਕੱਲ੍ਹ ਦੇਖ ਲਵਾਂਗੇ।", "It's late, {name}. Rest now, we'll see tomorrow."),
                            Line("ਸ਼ੁਭ ਰਾਤ। ਚੰਗੀ ਨੀਂਦ ਲੈ।", "Good night. Sleep well.")],
                    .funny: [Line("ਜੋ ਵੀ ਦੇਖ ਰਿਹਾ ਹੈਂ, ਕੱਲ੍ਹ ਵੀ ਉੱਥੇ ਹੀ ਹੋਵੇਗਾ। ਸੌਂ ਜਾ।", "Whatever you're watching will still be there tomorrow. Sleep."),
                             Line("ਗਲੀ ਦੇ ਕੁੱਤੇ ਵੀ ਸੌਂ ਗਏ। ਤੂੰ ਵੀ ਸੌਂ ਜਾ।", "Even the street dogs are asleep. You too.")],
                ],
                .morning: [
                    .strict: [Line("ਸ਼ੁਭ ਸਵੇਰ। ਸਵਖਤੇ ਉੱਠਣਾ ਅੱਧੀ ਜਿੱਤ ਹੈ। ਚੱਲ ਸ਼ੁਰੂ ਕਰ।", "Good morning. Waking early is half the battle. Get going."),
                              Line("ਸਵੇਰ ਹੋ ਗਈ। ਬਿਸਤਰਾ ਠੀਕ ਕਰ। ਫਿਰ ਬਾਕੀ ਸਭ।", "It's morning. Make your bed. Then everything else.")],
                    .soft: [Line("ਸ਼ੁਭ ਸਵੇਰ {name}। ਦਿਨ ਚੰਗਾ ਲੰਘੇ। ਨਾਸ਼ਤਾ ਜ਼ਰੂਰ ਕਰਨਾ।", "Good morning {name}. Have a good day. Do eat breakfast."),
                            Line("ਨਵਾਂ ਦਿਨ। ਪਾਣੀ ਅਤੇ ਇੱਕ ਸਟ੍ਰੈੱਚ ਨਾਲ ਸ਼ੁਰੂ ਕਰ।", "A new day. Start with water and a stretch.")],
                    .funny: [Line("ਸ਼ੁਭ ਸਵੇਰ! ਸੂਰਜ ਬਿਨਾਂ ਇਜਾਜ਼ਤ ਚੜ੍ਹ ਗਿਆ। ਤੂੰ ਵੀ ਉੱਠ।", "Good morning! The sun rose without permission. You rise too."),
                             Line("ਉੱਠ ਉੱਠ। ਨਾਸ਼ਤਾ ਆਪਸ਼ਨਲ ਨਹੀਂ ਹੈ।", "Up, up. Breakfast is not optional.")],
                ],
                .lowBattery: [
                    .strict: [Line("ਬੈਟਰੀ ਘੱਟ ਹੈ। ਚਾਰਜਰ ਲਾ। ਕਿੰਨੀ ਵਾਰ ਕਹਿਣਾ ਪਵੇਗਾ?", "Battery is low. Plug in the charger. How many times must I say it?"),
                              Line("ਲੈਪਟਾਪ ਬੰਦ ਹੋਣ ਤੋਂ ਪਹਿਲਾਂ ਚਾਰਜ ਕਰ। ਫ਼ੋਨ ਵੀ।", "Charge the laptop before it dies. Phone too.")],
                    .soft: [Line("ਬੈਟਰੀ ਘੱਟ ਹੋ ਰਹੀ ਹੈ {name}। ਚਾਰਜਰ ਲਾ ਦੇ।", "Battery is getting low, {name}. Plug in the charger."),
                            Line("ਚਾਰਜਰ, {name}। ਬੰਦ ਹੋਣ ਤੋਂ ਪਹਿਲਾਂ।", "Charger, {name}. Before it switches off.")],
                    .funny: [Line("ਲੈਪਟਾਪ ਪਿਆਸਾ ਹੈ। ਬਿਜਲੀ ਪਿਲਾ।", "The laptop is thirsty. Give it electricity."),
                             Line("ਲੋ ਬੈਟਰੀ। ਚਾਰਜਰ ਸਜਾਵਟ ਨਹੀਂ ਹੈ।", "Low battery. The charger is not decoration.")],
                ],
                .focusBreak: [
                    .strict: [Line("ਇੱਕ ਮਿੰਟ ਸਕ੍ਰੀਨ ਤੋਂ ਨਜ਼ਰ ਹਟਾ। ਦੂਰ ਦੇਖ।", "Eyes off the screen for a minute. Look far away."),
                              Line("ਸਕ੍ਰੀਨ ਸਕ੍ਰੀਨ ਸਕ੍ਰੀਨ। ਅੱਖਾਂ ਨੂੰ ਆਰਾਮ ਦੇ।", "Screen, screen, screen. Rest your eyes.")],
                    .soft: [Line("ਅੱਖਾਂ ਨੂੰ ਥੋੜ੍ਹਾ ਆਰਾਮ ਦੇ {name}। ਖਿੜਕੀ ਤੋਂ ਬਾਹਰ ਦੇਖ।", "Rest your eyes a little, {name}. Look out of the window."),
                            Line("ਵੀਹ ਸਕਿੰਟ ਅੱਖਾਂ ਬੰਦ ਕਰ। ਚੱਲ।", "Close your eyes for twenty seconds. Go on.")],
                    .funny: [Line("ਅੱਖ ਝਪਕ। ਹਾਂ ਤੂੰ। ਦਸ ਮਿੰਟ ਤੋਂ ਨਹੀਂ ਝਪਕੀ।", "Blink. Yes, you. You haven't blinked in ten minutes."),
                             Line("ਅੱਖਾਂ ਨੇ ਛੁੱਟੀ ਮੰਗੀ ਹੈ। ਦੇ ਦੇ।", "Your eyes have asked for leave. Grant it.")],
                ],
                .unplug: [
                    .strict: [Line("ਬੈਟਰੀ ਫੁੱਲ ਹੈ। ਚਾਰਜਰ ਕੱਢ। ਬਿਜਲੀ ਮੁਫ਼ਤ ਨਹੀਂ ਆਉਂਦੀ।", "Battery is full. Take the charger out. Electricity isn't free."),
                             Line("ਸੌ ਪ੍ਰਤੀਸ਼ਤ ਹੋ ਗਿਆ। ਅਨਪਲੱਗ ਕਰ। ਬੈਟਰੀ ਫੁਲਾਉਣੀ ਹੈ?", "It's at 100 percent. Unplug it. Do you want the battery to swell?")],
                    .soft: [Line("ਪੂਰਾ ਚਾਰਜ ਹੋ ਗਿਆ {name}। ਹੁਣ ਚਾਰਜਰ ਕੱਢ ਸਕਦੇ ਹੋ।", "It's fully charged, {name}. You can unplug it now."),
                             Line("ਚਾਰਜਰ ਹੁਣ ਹਟਾ ਦੇ। ਬੈਟਰੀ ਦੀ ਉਮਰ ਵਧੇਗੀ।", "Take the charger off now. The battery will live longer.")],
                    .funny: [Line("ਸੌ 'ਤੇ ਹੈ। ਲਾਈ ਰੱਖਣ ਨਾਲ ਇੱਕ ਸੌ ਦਸ ਨਹੀਂ ਹੋਣਾ।", "It's at 100. Keeping it plugged in won't make it 110."),
                             Line("ਲੈਪਟਾਪ ਦਾ ਪੇਟ ਭਰ ਗਿਆ। ਹੁਣ ਖੁਆਉਣਾ ਬੰਦ ਕਰ।", "The laptop's stomach is full. Stop feeding it.")],
                ],
                .trash: [
                    .strict: [Line("ਟ੍ਰੈਸ਼ ਭਰ ਗਿਆ ਹੈ। ਖਾਲੀ ਕਰ। ਹੁਣੇ।", "The Trash is full. Empty it. Now."),
                             Line("ਇਹ ਕੰਪਿਊਟਰ ਹੈ ਜਾਂ ਕਬਾੜ ਦੀ ਦੁਕਾਨ? ਟ੍ਰੈਸ਼ ਸਾਫ਼ ਕਰ।", "Is this a computer or a junk shop? Clear the Trash.")],
                    .soft: [Line("ਟ੍ਰੈਸ਼ ਵਿੱਚ ਬਹੁਤ ਕੁਝ ਜਮ੍ਹਾ ਹੋ ਗਿਆ {name}। ਸਮਾਂ ਮਿਲੇ ਤਾਂ ਸਾਫ਼ ਕਰ ਦੇ।", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                             Line("ਥੋੜ੍ਹੀ ਸਫ਼ਾਈ: ਟ੍ਰੈਸ਼ ਖਾਲੀ ਕਰ ਦੇ।", "A little cleaning: empty the Trash.")],
                    .funny: [Line("ਟ੍ਰੈਸ਼ ਵਿੱਚ Documents ਤੋਂ ਵੱਧ ਫ਼ਾਈਲਾਂ ਹਨ। ਖਾਲੀ ਕਰ।", "The Trash has more files than Documents. Empty it."),
                             Line("ਕੂੜਾ ਫੈਲਿਆ ਹੋਇਆ ਹੈ। ਇਹ ਘਰ ਹੈ, ਡੰਪਿੰਗ ਗਰਾਊਂਡ ਨਹੀਂ।", "Rubbish everywhere. This is a home, not a dumping ground.")],
                ],
            ]
        ),

        .marathi: LanguagePack(
            welcome: Line("नमस्कार {name}. मी {papa}. आतापासून मी लक्ष ठेवीन. वेळेवर जेव.", "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "बरं बाबा",
            snooze: "10 मिनिटांनी",
            chappal: Line("दोनदा सांगितलं. आता चप्पल उडेल.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [.soft: [Line("जेवलास का {name}? थोडा ब्रेक घे आणि जेव.", "Have you eaten, {name}? Take a break and eat."),
                                Line("आधी जेवण, मग लॅपटॉप. घरचा नियम आहे.", "Food first, laptop later. House rule."),
                                Line("आईने विचारायला सांगितलं: जेवलास का?", "Aai asked me to check: did you eat?")]],
                .water: [.soft: [Line("थोडं पाणी पी {name}.", "Have some water, {name}."),
                                 Line("एक ग्लास पाणी, मग काम.", "One glass of water, then work."),
                                 Line("पाणी. चहा नाही. पाणी.", "Water. Not chai. Water.")]],
                .move: [.soft: [Line("खूप वेळ बसला आहेस. थोडं चालून ये.", "You've been sitting a long time. Walk a bit."),
                                Line("दोन मिनिटं उठून फिर {name}.", "Get up and walk for two minutes, {name}.")]],
                .callHome: [.soft: [Line("आईला तुझा आवाज ऐकून बरं वाटेल. एक फोन कर.", "Aai would love to hear your voice. Give her a call."),
                                    Line("आज घरी फोन कर {name}. छोटा असला तरी चालेल.", "Call home today, {name}. Even a short one.")]],
                .bedtime: [.soft: [Line("उशीर झाला {name}. आता झोप, उद्या बघू.", "It's late, {name}. Sleep now, we'll see tomorrow."),
                                   Line("शुभ रात्री. नीट झोप.", "Good night. Sleep well.")]],
                .morning: [.soft: [Line("सुप्रभात {name}. दिवस चांगला जावो. नाश्ता नक्की कर.", "Good morning {name}. Have a good day. Do eat breakfast."),
                                   Line("नवा दिवस. पाणी आणि एक स्ट्रेच ने सुरू कर.", "A new day. Start with water and a stretch.")]],
                .lowBattery: [.soft: [Line("बॅटरी कमी होत आहे {name}. चार्जर लाव.", "Battery is getting low, {name}. Plug in the charger."),
                                      Line("लॅपटॉप बंद होण्याआधी चार्ज कर.", "Charge the laptop before it dies.")]],
                .focusBreak: [.soft: [Line("डोळ्यांना थोडा आराम दे {name}. खिडकीतून बाहेर बघ.", "Rest your eyes a little, {name}. Look out of the window."),
                                      Line("वीस सेकंद डोळे बंद कर.", "Close your eyes for twenty seconds.")]],
                .unplug: [.soft: [Line("पूर्ण चार्ज झालं {name}. आता चार्जर काढ.", "It's fully charged, {name}. Unplug it now."),
                                  Line("चार्जर आता काढून ठेव. बॅटरी जास्त टिकेल.", "Take the charger off now. The battery will last longer.")]],
                .trash: [.soft: [Line("ट्रॅशमध्ये खूप साचलं आहे {name}. वेळ मिळाला तर साफ कर.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                                 Line("थोडी साफसफाई: ट्रॅश रिकामा कर.", "A little cleaning: empty the Trash.")]],
            ]
        ),

        .gujarati: LanguagePack(
            welcome: Line("નમસ્તે {name}. હું {papa}. હવેથી હું ધ્યાન રાખીશ. સમયસર જમી લે.", "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "સારું પપ્પા",
            snooze: "10 મિનિટ પછી",
            chappal: Line("બે વાર કહ્યું. હવે ચંપલ ઉડશે.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [.soft: [Line("જમ્યો {name}? થોડો બ્રેક લઈને જમી લે.", "Have you eaten, {name}? Take a break and eat."),
                                Line("પહેલા જમવાનું, પછી લેપટોપ. ઘરનો નિયમ છે.", "Food first, laptop later. House rule."),
                                Line("મમ્મીએ પૂછવા કહ્યું: જમ્યો?", "Mummy asked me to check: did you eat?")]],
                .water: [.soft: [Line("થોડું પાણી પી લે {name}.", "Have some water, {name}."),
                                 Line("એક ગ્લાસ પાણી, પછી કામ.", "One glass of water, then work."),
                                 Line("પાણી. ચા નહીં. પાણી.", "Water. Not chai. Water.")]],
                .move: [.soft: [Line("બહુ વાર બેઠો છે. થોડું ચાલી લે.", "You've been sitting a long time. Walk a bit."),
                                Line("બે મિનિટ ઊભો થઈને ફર {name}.", "Get up and walk for two minutes, {name}.")]],
                .callHome: [.soft: [Line("મમ્મીને તારો અવાજ સાંભળીને સારું લાગશે. એક ફોન કરી દે.", "Mummy would love to hear your voice. Give her a call."),
                                    Line("આજે ઘરે ફોન કરજે {name}. નાનો હોય તો પણ ચાલે.", "Call home today, {name}. Even a short one.")]],
                .bedtime: [.soft: [Line("મોડું થયું {name}. હવે આરામ કર, કાલે જોઈશું.", "It's late, {name}. Rest now, we'll see tomorrow."),
                                   Line("શુભ રાત્રિ. સારી રીતે સૂઈ જા.", "Good night. Sleep well.")]],
                .morning: [.soft: [Line("શુભ સવાર {name}. દિવસ સારો જાય. નાસ્તો જરૂર કરજે.", "Good morning {name}. Have a good day. Do eat breakfast."),
                                   Line("નવો દિવસ. પાણી અને એક સ્ટ્રેચથી શરૂ કર.", "A new day. Start with water and a stretch.")]],
                .lowBattery: [.soft: [Line("બેટરી ઓછી થઈ રહી છે {name}. ચાર્જર લગાવ.", "Battery is getting low, {name}. Plug in the charger."),
                                      Line("લેપટોપ બંધ થાય એ પહેલા ચાર્જ કર.", "Charge the laptop before it dies.")]],
                .focusBreak: [.soft: [Line("આંખોને થોડો આરામ આપ {name}. બારીની બહાર જો.", "Rest your eyes a little, {name}. Look out of the window."),
                                      Line("વીસ સેકન્ડ આંખો બંધ કર.", "Close your eyes for twenty seconds.")]],
                .unplug: [.soft: [Line("પૂરું ચાર્જ થઈ ગયું {name}. હવે ચાર્જર કાઢી લે.", "It's fully charged, {name}. Unplug it now."),
                                  Line("ચાર્જર હવે કાઢી નાખ. બેટરી વધુ ચાલશે.", "Take the charger off now. The battery will last longer.")]],
                .trash: [.soft: [Line("ટ્રૅશમાં બહુ બધું ભરાઈ ગયું છે {name}. સમય મળે તો સાફ કરી દે.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                                 Line("થોડી સફાઈ: ટ્રૅશ ખાલી કરી દે.", "A little cleaning: empty the Trash.")]],
            ]
        ),

        .bengali: LanguagePack(
            welcome: Line("নমস্কার {name}। আমি {papa}। এখন থেকে আমি খেয়াল রাখব। সময়মতো খেয়ে নিস।", "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "আচ্ছা বাবা",
            snooze: "১০ মিনিট পরে",
            chappal: Line("দুবার বলেছি। এবার চটি উড়বে।", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [.soft: [Line("খেয়েছিস {name}? একটু বিরতি নিয়ে খেয়ে নে।", "Have you eaten, {name}? Take a break and eat."),
                                Line("আগে খাওয়া, তারপর ল্যাপটপ। বাড়ির নিয়ম।", "Food first, laptop later. House rule."),
                                Line("মা জিজ্ঞেস করতে বলল: খেয়েছিস?", "Ma asked me to check: did you eat?")]],
                .water: [.soft: [Line("একটু জল খেয়ে নে {name}।", "Have some water, {name}."),
                                 Line("এক গ্লাস জল, তারপর কাজ।", "One glass of water, then work."),
                                 Line("জল। চা নয়। জল।", "Water. Not cha. Water.")]],
                .move: [.soft: [Line("অনেকক্ষণ বসে আছিস। একটু হেঁটে আয়।", "You've been sitting a long time. Walk a bit."),
                                Line("দুই মিনিট উঠে হাঁট {name}।", "Get up and walk for two minutes, {name}.")]],
                .callHome: [.soft: [Line("মা তোর গলা শুনলে খুশি হবে। একটা ফোন কর।", "Ma would be happy to hear your voice. Give her a call."),
                                    Line("আজ বাড়িতে ফোন করিস {name}। ছোট হলেও চলবে।", "Call home today, {name}. Even a short one.")]],
                .bedtime: [.soft: [Line("রাত হয়ে গেছে {name}। এখন ঘুমিয়ে পড়, কাল দেখা যাবে।", "It's late, {name}. Sleep now, we'll see tomorrow."),
                                   Line("শুভ রাত্রি। ভালো করে ঘুমা।", "Good night. Sleep well.")]],
                .morning: [.soft: [Line("সুপ্রভাত {name}। দিনটা ভালো যাক। সকালের খাবার অবশ্যই খাবি।", "Good morning {name}. Have a good day. Do eat breakfast."),
                                   Line("নতুন দিন। জল আর একটু স্ট্রেচ দিয়ে শুরু কর।", "A new day. Start with water and a stretch.")]],
                .lowBattery: [.soft: [Line("ব্যাটারি কমে যাচ্ছে {name}। চার্জার লাগা।", "Battery is getting low, {name}. Plug in the charger."),
                                      Line("ল্যাপটপ বন্ধ হওয়ার আগে চার্জ কর।", "Charge the laptop before it dies.")]],
                .focusBreak: [.soft: [Line("চোখকে একটু বিশ্রাম দে {name}। জানলার বাইরে দেখ।", "Rest your eyes a little, {name}. Look out of the window."),
                                      Line("কুড়ি সেকেন্ড চোখ বন্ধ কর।", "Close your eyes for twenty seconds.")]],
                .unplug: [.soft: [Line("পুরো চার্জ হয়ে গেছে {name}। এখন চার্জার খুলে দে।", "It's fully charged, {name}. Unplug it now."),
                                  Line("চার্জার এখন সরিয়ে দে। ব্যাটারি বেশি দিন টিকবে।", "Take the charger off now. The battery will last longer.")]],
                .trash: [.soft: [Line("ট্র্যাশে অনেক কিছু জমে গেছে {name}। সময় পেলে পরিষ্কার করে দে।", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                                 Line("একটু পরিষ্কার: ট্র্যাশ খালি করে দে।", "A little cleaning: empty the Trash.")]],
            ]
        ),

        .malayalam: LanguagePack(
            welcome: Line("നമസ്കാരം {name}. ഞാൻ {papa}. ഇനി ഞാൻ നോക്കിക്കോളാം. സമയത്ത് ഭക്ഷണം കഴിക്കണം.", "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "ശരി അച്ഛാ",
            snooze: "10 മിനിറ്റ്",
            chappal: Line("രണ്ടു തവണ പറഞ്ഞു. ഇനി ചെരിപ്പ് പറക്കും.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [.soft: [Line("ഭക്ഷണം കഴിച്ചോ {name}? ഒരു ബ്രേക്ക് എടുത്ത് കഴിക്ക്.", "Have you eaten, {name}? Take a break and eat."),
                                Line("ആദ്യം ഭക്ഷണം, പിന്നെ ലാപ്ടോപ്. വീട്ടിലെ നിയമമാണ്.", "Food first, laptop later. House rule."),
                                Line("അമ്മ ചോദിക്കാൻ പറഞ്ഞു: കഴിച്ചോ?", "Amma asked me to check: did you eat?")]],
                .water: [.soft: [Line("കുറച്ച് വെള്ളം കുടിക്ക് {name}.", "Have some water, {name}."),
                                 Line("ഒരു ഗ്ലാസ് വെള്ളം, പിന്നെ ജോലി.", "One glass of water, then work."),
                                 Line("വെള്ളം. ചായ അല്ല. വെള്ളം.", "Water. Not chaya. Water.")]],
                .move: [.soft: [Line("ഒരുപാട് നേരം ഇരുന്നു. കുറച്ച് നടക്ക്.", "You've been sitting a long time. Walk a bit."),
                                Line("രണ്ട് മിനിറ്റ് എഴുന്നേറ്റ് നടക്ക് {name}.", "Get up and walk for two minutes, {name}.")]],
                .callHome: [.soft: [Line("അമ്മയ്ക്ക് നിന്റെ ശബ്ദം കേട്ടാൽ സന്തോഷമാകും. ഒന്ന് വിളിക്ക്.", "Amma would be happy to hear your voice. Give her a call."),
                                    Line("ഇന്ന് വീട്ടിലേക്ക് വിളിക്കണം {name}. ചെറുതായാലും മതി.", "Call home today, {name}. Even a short one.")]],
                .bedtime: [.soft: [Line("വൈകി {name}. ഇപ്പോൾ വിശ്രമിക്ക്, നാളെ നോക്കാം.", "It's late, {name}. Rest now, we'll see tomorrow."),
                                   Line("ശുഭരാത്രി. നന്നായി ഉറങ്ങ്.", "Good night. Sleep well.")]],
                .morning: [.soft: [Line("സുപ്രഭാതം {name}. നല്ല ദിവസമാകട്ടെ. പ്രഭാതഭക്ഷണം കഴിക്കണം.", "Good morning {name}. Have a good day. Do eat breakfast."),
                                   Line("പുതിയ ദിവസം. വെള്ളവും ഒരു സ്ട്രെച്ചും കൊണ്ട് തുടങ്ങ്.", "A new day. Start with water and a stretch.")]],
                .lowBattery: [.soft: [Line("ബാറ്ററി കുറയുന്നു {name}. ചാർജർ ഇട്.", "Battery is getting low, {name}. Plug in the charger."),
                                      Line("ലാപ്ടോപ് ഓഫ് ആകുന്നതിന് മുൻപ് ചാർജ് ചെയ്യ്.", "Charge the laptop before it dies.")]],
                .focusBreak: [.soft: [Line("കണ്ണിന് കുറച്ച് വിശ്രമം കൊടുക്ക് {name}. ജനലിലൂടെ പുറത്തേക്ക് നോക്ക്.", "Rest your eyes a little, {name}. Look out of the window."),
                                      Line("ഇരുപത് സെക്കൻഡ് കണ്ണടയ്ക്ക്.", "Close your eyes for twenty seconds.")]],
                .unplug: [.soft: [Line("ഫുൾ ചാർജ് ആയി {name}. ഇപ്പോൾ ചാർജർ എടുത്തോ.", "It's fully charged, {name}. Unplug it now."),
                                  Line("ചാർജർ ഇപ്പോൾ മാറ്റിക്കോ. ബാറ്ററി കൂടുതൽ കാലം നിൽക്കും.", "Take the charger off now. The battery will last longer.")]],
                .trash: [.soft: [Line("ട്രാഷിൽ ഒരുപാട് കൂടിക്കിടക്കുന്നു {name}. സമയം കിട്ടുമ്പോൾ വൃത്തിയാക്ക്.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                                 Line("ഒരു ചെറിയ വൃത്തിയാക്കൽ: ട്രാഷ് കാലിയാക്ക്.", "A little cleaning: empty the Trash.")]],
            ]
        ),

        .telugu: LanguagePack(
            welcome: Line("నమస్తే {name}. నేను {papa}. ఇక నుంచి నేను చూసుకుంటాను. సమయానికి తిను.", "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "సరే నాన్న",
            snooze: "10 నిమిషాలు",
            chappal: Line("రెండు సార్లు చెప్పాను. ఇప్పుడు చెప్పు ఎగురుతుంది.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [.soft: [Line("అన్నం తిన్నావా {name}? కొంచెం బ్రేక్ తీసుకుని తిను.", "Have you eaten, {name}? Take a break and eat."),
                                Line("ముందు భోజనం, తర్వాత ల్యాప్‌టాప్. ఇంటి రూల్.", "Food first, laptop later. House rule."),
                                Line("అమ్మ అడగమని చెప్పింది: తిన్నావా?", "Amma asked me to check: did you eat?")]],
                .water: [.soft: [Line("కొంచెం నీళ్లు తాగు {name}.", "Have some water, {name}."),
                                 Line("ఒక గ్లాసు నీళ్లు, తర్వాత పని.", "One glass of water, then work."),
                                 Line("నీళ్లు. టీ కాదు. నీళ్లు.", "Water. Not tea. Water.")]],
                .move: [.soft: [Line("చాలా సేపు కూర్చున్నావు. కొంచెం నడువు.", "You've been sitting a long time. Walk a bit."),
                                Line("రెండు నిమిషాలు లేచి నడువు {name}.", "Get up and walk for two minutes, {name}.")]],
                .callHome: [.soft: [Line("అమ్మకు నీ గొంతు వింటే సంతోషం. ఒక ఫోన్ చెయ్.", "Amma would be happy to hear your voice. Give her a call."),
                                    Line("ఈరోజు ఇంటికి ఫోన్ చెయ్ {name}. చిన్నదైనా సరే.", "Call home today, {name}. Even a short one.")]],
                .bedtime: [.soft: [Line("ఆలస్యం అయింది {name}. ఇప్పుడు పడుకో, రేపు చూద్దాం.", "It's late, {name}. Sleep now, we'll see tomorrow."),
                                   Line("శుభరాత్రి. బాగా నిద్రపో.", "Good night. Sleep well.")]],
                .morning: [.soft: [Line("శుభోదయం {name}. రోజు బాగుండాలి. బ్రేక్‌ఫాస్ట్ తప్పకుండా తిను.", "Good morning {name}. Have a good day. Do eat breakfast."),
                                   Line("కొత్త రోజు. నీళ్లు, ఒక స్ట్రెచ్‌తో మొదలుపెట్టు.", "A new day. Start with water and a stretch.")]],
                .lowBattery: [.soft: [Line("బ్యాటరీ తగ్గుతోంది {name}. ఛార్జర్ పెట్టు.", "Battery is getting low, {name}. Plug in the charger."),
                                      Line("ల్యాప్‌టాప్ ఆగిపోయేముందు ఛార్జ్ చెయ్.", "Charge the laptop before it dies.")]],
                .focusBreak: [.soft: [Line("కళ్లకు కొంచెం విశ్రాంతి ఇవ్వు {name}. కిటికీలోంచి బయటకు చూడు.", "Rest your eyes a little, {name}. Look out of the window."),
                                      Line("ఇరవై సెకన్లు కళ్లు మూసుకో.", "Close your eyes for twenty seconds.")]],
                .unplug: [.soft: [Line("పూర్తిగా ఛార్జ్ అయింది {name}. ఇప్పుడు ఛార్జర్ తీసేయ్.", "It's fully charged, {name}. Unplug it now."),
                                  Line("ఛార్జర్ ఇప్పుడు తీసేయ్. బ్యాటరీ ఎక్కువ కాలం ఉంటుంది.", "Take the charger off now. The battery will last longer.")]],
                .trash: [.soft: [Line("ట్రాష్‌లో చాలా పేరుకుపోయింది {name}. సమయం దొరికితే క్లీన్ చెయ్.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                                 Line("చిన్న శుభ్రత: ట్రాష్ ఖాళీ చెయ్.", "A little cleaning: empty the Trash.")]],
            ]
        ),

        .kannada: LanguagePack(
            welcome: Line("ನಮಸ್ಕಾರ {name}. ನಾನು {papa}. ಇನ್ನು ಮುಂದೆ ನಾನು ನೋಡಿಕೊಳ್ಳುತ್ತೇನೆ. ಸಮಯಕ್ಕೆ ಊಟ ಮಾಡು.", "Hello {name}. I'm {papa}. From now on I'll keep an eye on you. Eat on time."),
            done: "ಸರಿ ಅಪ್ಪ",
            snooze: "10 ನಿಮಿಷ",
            chappal: Line("ಎರಡು ಸಲ ಹೇಳಿದೆ. ಈಗ ಚಪ್ಪಲಿ ಹಾರುತ್ತೆ.", "I told you twice. Now the chappal flies."),
            messages: [
                .meal: [.soft: [Line("ಊಟ ಆಯ್ತಾ {name}? ಸ್ವಲ್ಪ ಬ್ರೇಕ್ ತೆಗೆದು ಊಟ ಮಾಡು.", "Have you eaten, {name}? Take a break and eat."),
                                Line("ಮೊದಲು ಊಟ, ಆಮೇಲೆ ಲ್ಯಾಪ್‌ಟಾಪ್. ಮನೆ ನಿಯಮ.", "Food first, laptop later. House rule."),
                                Line("ಅಮ್ಮ ಕೇಳಲು ಹೇಳಿದ್ರು: ಊಟ ಆಯ್ತಾ?", "Amma asked me to check: did you eat?")]],
                .water: [.soft: [Line("ಸ್ವಲ್ಪ ನೀರು ಕುಡಿ {name}.", "Have some water, {name}."),
                                 Line("ಒಂದು ಲೋಟ ನೀರು, ಆಮೇಲೆ ಕೆಲಸ.", "One glass of water, then work."),
                                 Line("ನೀರು. ಚಾ ಅಲ್ಲ. ನೀರು.", "Water. Not chai. Water.")]],
                .move: [.soft: [Line("ತುಂಬಾ ಹೊತ್ತು ಕೂತಿದ್ದೀಯ. ಸ್ವಲ್ಪ ನಡೆದು ಬಾ.", "You've been sitting a long time. Walk a bit."),
                                Line("ಎರಡು ನಿಮಿಷ ಎದ್ದು ನಡಿ {name}.", "Get up and walk for two minutes, {name}.")]],
                .callHome: [.soft: [Line("ಅಮ್ಮಂಗೆ ನಿನ್ನ ಧ್ವನಿ ಕೇಳಿದ್ರೆ ಖುಷಿ ಆಗ್ತದೆ. ಒಂದು ಫೋನ್ ಮಾಡು.", "Amma would be happy to hear your voice. Give her a call."),
                                    Line("ಇವತ್ತು ಮನೆಗೆ ಫೋನ್ ಮಾಡು {name}. ಚಿಕ್ಕದಾದ್ರೂ ಸರಿ.", "Call home today, {name}. Even a short one.")]],
                .bedtime: [.soft: [Line("ತಡ ಆಯ್ತು {name}. ಈಗ ಮಲಗು, ನಾಳೆ ನೋಡೋಣ.", "It's late, {name}. Sleep now, we'll see tomorrow."),
                                   Line("ಶುಭರಾತ್ರಿ. ಚೆನ್ನಾಗಿ ನಿದ್ದೆ ಮಾಡು.", "Good night. Sleep well.")]],
                .morning: [.soft: [Line("ಶುಭೋದಯ {name}. ದಿನ ಚೆನ್ನಾಗಿರಲಿ. ತಿಂಡಿ ತಪ್ಪದೇ ತಿನ್ನು.", "Good morning {name}. Have a good day. Do eat breakfast."),
                                   Line("ಹೊಸ ದಿನ. ನೀರು ಮತ್ತು ಒಂದು ಸ್ಟ್ರೆಚ್‌ನಿಂದ ಶುರು ಮಾಡು.", "A new day. Start with water and a stretch.")]],
                .lowBattery: [.soft: [Line("ಬ್ಯಾಟರಿ ಕಡಿಮೆ ಆಗ್ತಿದೆ {name}. ಚಾರ್ಜರ್ ಹಾಕು.", "Battery is getting low, {name}. Plug in the charger."),
                                      Line("ಲ್ಯಾಪ್‌ಟಾಪ್ ಆಫ್ ಆಗೋ ಮುಂಚೆ ಚಾರ್ಜ್ ಮಾಡು.", "Charge the laptop before it dies.")]],
                .focusBreak: [.soft: [Line("ಕಣ್ಣಿಗೆ ಸ್ವಲ್ಪ ವಿಶ್ರಾಂತಿ ಕೊಡು {name}. ಕಿಟಕಿಯಿಂದ ಹೊರಗೆ ನೋಡು.", "Rest your eyes a little, {name}. Look out of the window."),
                                      Line("ಇಪ್ಪತ್ತು ಸೆಕೆಂಡ್ ಕಣ್ಣು ಮುಚ್ಚು.", "Close your eyes for twenty seconds.")]],
                .unplug: [.soft: [Line("ಪೂರ್ತಿ ಚಾರ್ಜ್ ಆಯ್ತು {name}. ಈಗ ಚಾರ್ಜರ್ ತೆಗಿ.", "It's fully charged, {name}. Unplug it now."),
                                  Line("ಚಾರ್ಜರ್ ಈಗ ತೆಗೆದಿಡು. ಬ್ಯಾಟರಿ ಹೆಚ್ಚು ದಿನ ಬಾಳುತ್ತೆ.", "Take the charger off now. The battery will last longer.")]],
                .trash: [.soft: [Line("ಟ್ರ್ಯಾಶ್‌ನಲ್ಲಿ ತುಂಬಾ ತುಂಬಿಕೊಂಡಿದೆ {name}. ಸಮಯ ಸಿಕ್ಕಾಗ ಕ್ಲೀನ್ ಮಾಡು.", "A lot has piled up in the Trash, {name}. Clear it when you get a minute."),
                                 Line("ಸ್ವಲ್ಪ ಸ್ವಚ್ಛತೆ: ಟ್ರ್ಯಾಶ್ ಖಾಲಿ ಮಾಡು.", "A little cleaning: empty the Trash.")]],
            ]
        ),
    ]
}
