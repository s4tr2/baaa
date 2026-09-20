import Foundation

/// Maa & Papa mode: the two of them speak with one voice. Wholesome on purpose;
/// with her in the room he does not shout, and there is no chappal. `{name}` is
/// what they call you, `{maa}` and `{papa}` their names.
struct TogetherPack {
    var welcome: Line
    /// For custom reminders and anything without a dedicated set.
    var general: [Line]
    var messages: [ReminderKind: [Line]]
}

extension MessageLibrary {
    /// Languages without their own lines borrow English for now.
    static func togetherPack(_ language: Language) -> TogetherPack {
        togetherPacks[language] ?? togetherPacks[.english]!
    }

    static func togetherLines(for kind: ReminderKind?, language: Language) -> [Line] {
        let pack = togetherPack(language)
        if let kind {
            if let own = pack.messages[kind], !own.isEmpty { return own }
            if let en = togetherPacks[.english]!.messages[kind], !en.isEmpty { return en }
        }
        return pack.general
    }

    static let togetherPacks: [Language: TogetherPack] = [
        .english: TogetherPack(
            welcome: "Hello {name}. It's both of us now. We'll remind you gently, and we are so proud of you.",
            general: ["We're right here, {name}. Do this one thing, then carry on.",
                      "Small things, done on time. That's all we ever asked.",
                      "Whatever you're building, we're cheering. Just look after yourself while you do it."],
            messages: [
                .meal: ["Have you eaten, {name}? Nothing you're doing matters more to us than that.",
                        "Go eat something warm. We'll wait right here.",
                        "Take a proper break and eat. Work will be there tomorrow, you matter today."],
                .water: ["Drink some water, {name}. Small sips, we're both watching, lovingly.",
                         "A glass of water. Then back to your brilliant work."],
                .move: ["Stretch a little, {name}. Your back is ours to worry about.",
                        "Walk to the window and back. Come on, we'll count."],
                .callHome: ["We miss your voice, {name}. Call when you can, even for two minutes.",
                            "No rush, no guilt. Just call us when you get a moment. We'll be here."],
                .bedtime: ["It's late, {name}. You've done enough today. Sleep well, we love you.",
                           "Laptop off, lights off. Tomorrow will feel kinder if you rest."],
                .morning: ["Good morning, {name}. Eat breakfast and have a lovely day. We're proud of you.",
                           "A new day. Water, a stretch, some breakfast. Start gently."],
                .lowBattery: ["Battery is low, {name}. Plug it in before it dies on you. Your phone too.",
                              "Charger, please. We don't want you losing your work."],
                .focusBreak: ["Give your eyes a rest, {name}. Look out of the window for a minute.",
                              "Blink, breathe, look far away. Twenty seconds, for us."],
                .unplug: ["It's fully charged. Unplug it, and stretch while you're up.",
                          "100 percent. Take the charger out, the battery lives longer."],
                .trash: ["The Trash has piled up, {name}. Clear it when you get a minute, it feels lighter.",
                         "A little tidy-up: empty the Trash. Just like your room, hmm?"],
            ]
        ),

        .hinglish: TogetherPack(
            welcome: Line("Namaste {name}. Ab hum dono hain. Pyaar se yaad dilayenge, aur haan, humein tum pe bahut garv hai.",
                          "Hello {name}. It's both of us now. We'll remind you gently, and we are so proud of you."),
            general: [Line("Hum yahin hain {name}. Yeh ek kaam kar lo, phir aage badho.", "We're right here, {name}. Do this one thing, then carry on."),
                      Line("Chhoti cheezein, time pe. Bas yahi toh maanga hai humne.", "Small things, on time. That's all we ever asked."),
                      Line("Jo bhi bana rahe ho, hum saath hain. Bas apna dhyan bhi rakho.", "Whatever you're building, we're with you. Just look after yourself too.")],
            messages: [
                .meal: [Line("Khaana khaya {name}? Tumhare kaam se zyada humein tumhari fikar hai.", "Have you eaten, {name}? We care about you more than your work."),
                        Line("Jao kuch garam kha lo. Hum yahin wait karenge.", "Go eat something warm. We'll wait right here."),
                        Line("Dhang se break lo aur khaana khao. Kaam kal bhi hoga, tum aaj zaroori ho.", "Take a proper break and eat. Work will be there tomorrow, you matter today.")],
                .water: [Line("Thoda paani pi lo {name}. Hum dono dekh rahe hain, pyaar se.", "Drink some water, {name}. We're both watching, lovingly."),
                         Line("Ek glass paani. Phir apna kamaal ka kaam.", "A glass of water. Then back to your brilliant work.")],
                .move: [Line("Thoda stretch kar lo {name}. Tumhari kamar ki chinta humari hai.", "Stretch a little, {name}. Your back is ours to worry about."),
                        Line("Khidki tak jao aur wapas aao. Chalo, hum ginte hain.", "Walk to the window and back. Come on, we'll count.")],
                .callHome: [Line("Tumhari awaaz sunne ka mann hai {name}. Jab time mile, do minute ka call kar lo.", "We miss your voice, {name}. Call when you can, even for two minutes."),
                            Line("Koi jaldi nahi, koi guilt nahi. Bas fursat mile toh phone karna. Hum yahin hain.", "No rush, no guilt. Just call when you get a moment. We'll be here.")],
                .bedtime: [Line("Der ho gayi {name}. Aaj ke liye bahut kiya. Accha so, hum tumse bahut pyaar karte hain.", "It's late, {name}. You've done enough today. Sleep well, we love you."),
                           Line("Laptop band, light band. Aaram karoge toh kal aur accha lagega.", "Laptop off, lights off. Rest, and tomorrow will feel kinder.")],
                .morning: [Line("Good morning {name}. Nashta karna, aur din accha ho. Humein tum pe garv hai.", "Good morning {name}. Eat breakfast and have a lovely day. We're proud of you."),
                           Line("Naya din. Paani, ek stretch, thoda nashta. Aaram se shuru karo.", "A new day. Water, a stretch, some breakfast. Start gently.")],
                .lowBattery: [Line("Battery kam hai {name}. Band hone se pehle charger laga do. Phone bhi.", "Battery is low, {name}. Plug in before it dies. Phone too."),
                              Line("Charger laga lo please. Tumhara kaam kharab na ho jaaye.", "Plug in the charger, please. We don't want you losing your work.")],
                .focusBreak: [Line("Aankhon ko rest do {name}. Ek minute khidki se bahar dekho.", "Rest your eyes, {name}. Look out of the window for a minute."),
                              Line("Palak jhapkao, saans lo, door dekho. Bees second humare liye.", "Blink, breathe, look far away. Twenty seconds, for us.")],
                .unplug: [Line("Full charge ho gaya. Charger nikaalo, aur uthe ho toh stretch bhi kar lo.", "Fully charged. Unplug it, and stretch while you're up."),
                          Line("100 percent. Charger hata do, battery lambi chalegi.", "100 percent. Take the charger off, the battery lives longer.")],
                .trash: [Line("Trash bhar gaya hai {name}. Fursat mein khaali kar do, halka lagega.", "The Trash has piled up, {name}. Empty it when you're free, it feels lighter."),
                         Line("Thodi safai: Trash khaali karo. Bilkul tumhare kamre jaise, hmm?", "A little tidy-up: empty the Trash. Just like your room, hmm?")],
            ]
        ),

        .hindi: TogetherPack(
            welcome: Line("नमस्ते {name}। अब हम दोनों हैं। प्यार से याद दिलाएँगे, और हाँ, हमें तुम पर बहुत गर्व है।",
                          "Hello {name}. It's both of us now. We'll remind you gently, and we are so proud of you."),
            general: [Line("हम यहीं हैं {name}। ये एक काम कर लो, फिर आगे बढ़ो।", "We're right here, {name}. Do this one thing, then carry on."),
                      Line("छोटी चीज़ें, समय पर। बस यही तो माँगा है हमने।", "Small things, on time. That's all we ever asked."),
                      Line("जो भी बना रहे हो, हम साथ हैं। बस अपना ध्यान भी रखो।", "Whatever you're building, we're with you. Just look after yourself too.")],
            messages: [
                .meal: [Line("खाना खाया {name}? तुम्हारे काम से ज़्यादा हमें तुम्हारी फ़िक्र है।", "Have you eaten, {name}? We care about you more than your work."),
                        Line("जाओ कुछ गरम खा लो। हम यहीं इंतज़ार करेंगे।", "Go eat something warm. We'll wait right here."),
                        Line("ढंग से ब्रेक लो और खाना खाओ। काम कल भी होगा, तुम आज ज़रूरी हो।", "Take a proper break and eat. Work will be there tomorrow, you matter today.")],
                .water: [Line("थोड़ा पानी पी लो {name}। हम दोनों देख रहे हैं, प्यार से।", "Drink some water, {name}. We're both watching, lovingly."),
                         Line("एक गिलास पानी। फिर अपना कमाल का काम।", "A glass of water. Then back to your brilliant work.")],
                .move: [Line("थोड़ा स्ट्रेच कर लो {name}। तुम्हारी कमर की चिंता हमारी है।", "Stretch a little, {name}. Your back is ours to worry about."),
                        Line("खिड़की तक जाओ और वापस आओ। चलो, हम गिनते हैं।", "Walk to the window and back. Come on, we'll count.")],
                .callHome: [Line("तुम्हारी आवाज़ सुनने का मन है {name}। समय मिले तो दो मिनट का फ़ोन कर लो।", "We miss your voice, {name}. Call when you can, even for two minutes."),
                            Line("कोई जल्दी नहीं, कोई गिल्ट नहीं। बस फ़ुरसत मिले तो फ़ोन करना। हम यहीं हैं।", "No rush, no guilt. Just call when you get a moment. We'll be here.")],
                .bedtime: [Line("देर हो गई {name}। आज के लिए बहुत किया। अच्छा सो, हम तुमसे बहुत प्यार करते हैं।", "It's late, {name}. You've done enough today. Sleep well, we love you."),
                           Line("लैपटॉप बंद, बत्ती बंद। आराम करोगे तो कल और अच्छा लगेगा।", "Laptop off, lights off. Rest, and tomorrow will feel kinder.")],
                .morning: [Line("सुप्रभात {name}। नाश्ता करना, और दिन अच्छा हो। हमें तुम पर गर्व है।", "Good morning {name}. Eat breakfast and have a lovely day. We're proud of you."),
                           Line("नया दिन। पानी, एक स्ट्रेच, थोड़ा नाश्ता। आराम से शुरू करो।", "A new day. Water, a stretch, some breakfast. Start gently.")],
                .lowBattery: [Line("बैटरी कम है {name}। बंद होने से पहले चार्जर लगा दो। फ़ोन भी।", "Battery is low, {name}. Plug in before it dies. Phone too."),
                              Line("चार्जर लगा लो प्लीज़। तुम्हारा काम ख़राब न हो जाए।", "Plug in the charger, please. We don't want you losing your work.")],
                .focusBreak: [Line("आँखों को आराम दो {name}। एक मिनट खिड़की से बाहर देखो।", "Rest your eyes, {name}. Look out of the window for a minute."),
                              Line("पलक झपकाओ, साँस लो, दूर देखो। बीस सेकंड हमारे लिए।", "Blink, breathe, look far away. Twenty seconds, for us.")],
                .unplug: [Line("पूरा चार्ज हो गया। चार्जर निकालो, और उठे हो तो स्ट्रेच भी कर लो।", "Fully charged. Unplug it, and stretch while you're up."),
                          Line("100 परसेंट। चार्जर हटा दो, बैटरी लंबी चलेगी।", "100 percent. Take the charger off, the battery lives longer.")],
                .trash: [Line("ट्रैश भर गया है {name}। फ़ुरसत में ख़ाली कर दो, हल्का लगेगा।", "The Trash has piled up, {name}. Empty it when you're free, it feels lighter."),
                         Line("थोड़ी सफ़ाई: ट्रैश ख़ाली करो। बिल्कुल तुम्हारे कमरे जैसे, हम्म?", "A little tidy-up: empty the Trash. Just like your room, hmm?")],
            ]
        ),
    ]
}
