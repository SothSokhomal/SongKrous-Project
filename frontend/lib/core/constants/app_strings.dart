/// Bilingual (EN / KH) app strings.
///
/// Map-based localisation keeps the scaffold free of codegen.
/// NOTE: Khmer copy was drafted without a native review — have a Khmer
/// speaker proofread before release (especially the safety guidance).
enum AppLang { en, km }

Map<AppLang, String> _k(String en, String km) => {
  AppLang.en: en,
  AppLang.km: km,
};

abstract final class AppStrings {
  static final Map<String, Map<AppLang, String>> _t = {
    // ── Brand / common ───────────────────────────────────────────────
    'app_name': _k('SONGKROUS', 'សង្គ្រោះ'),
    'next': _k('Next', 'បន្ទាប់'),
    'back': _k('Back', 'ថយក្រោយ'),
    'call': _k('Call', 'ហៅ'),
    'close': _k('Close', 'បិទ'),
    'lang_km': _k('ភាសាខ្មែរ', 'ភាសាខ្មែរ'),
    'lang_en': _k('English', 'English'),

    // ── Onboarding ───────────────────────────────────────────────────
    'onb_title': _k(
      'Emergency help, simplified',
      'ជំនួយសង្គ្រោះបន្ទាន់ កាន់តែងាយស្រួល',
    ),
    'onb_sub': _k(
      'Know what Songkrous does before you need it.',
      'ស្វែងយល់ពីមុខងារសំខាន់ៗរបស់សង្គ្រោះ',
    ),
    'feat_help': _k('One-Tap Help', 'ជំនួយដោយចុចតែម្តង'),
    'feat_help_sub': _k(
      'Instantly reach nearby hospitals, police, or fire stations without memorizing numbers.',
      'ទាក់ទងទៅមន្ទីរពេទ្យ ប៉ូលិស ឬពន្លត់អគ្គិភ័យដែលនៅជិតបំផុតភ្លាមៗ ដោយមិនបាច់ចាំលេខទូរសព្ទ។',
    ),
    'feat_gps': _k('Auto-GPS Location', 'កំណត់ទីតាំងដោយស្វ័យប្រវត្តិ'),
    'feat_gps_sub': _k(
      'Detects your exact street and Khan automatically so you can share it clearly during panic.',
      'បង្ហាញឈ្មោះផ្លូវ និងខណ្ឌរបស់អ្នកដោយស្វ័យប្រវត្តិ ដើម្បីងាយស្រួលប្រាប់ទៅអ្នកជួយសង្គ្រោះ។',
    ),
    'feat_aid': _k('First-Aid Guidance', 'ការណែនាំសង្គ្រោះបឋម'),
    'feat_aid_sub': _k(
      'Calm, step-by-step safety tips to follow while emergency responders are on the way.',
      'ផ្តល់ដំបូន្មានសុវត្ថិភាពជាជំហានៗ ដើម្បីជួយអ្នកឱ្យស្ងប់អារម្មណ៍ពេលកំពុងរង់ចាំជំនួយ។',
    ),
    'continue': _k('Continue', 'បន្ត'),
    'step_of': _k('Step {n} of {total}', 'ជំហានទី {n} នៃ {total}'),
    'enter_phone': _k('Enter your phone number', 'បញ្ចូលលេខទូរស័ព្ទរបស់អ្នក'),
    'phone_reason': _k(
      'Used only for emergency callback or SMS.',
      'ប្រើសម្រាប់តែការហៅត្រឡប់ ឬសារខ្លី ក្នុងគ្រាអាសន្នប៉ុណ្ណោះ។',
    ),
    'phone_hint': _k('12 345 678', '១២ ៣៤៥ ៦៧៨'),
    'skip': _k('Skip for now', 'រំលងសិន'),
    'gps_dialog_title': _k(
      'Allow "Songkrous" to use your location?',
      'អនុញ្ញាតឱ្យ "សង្គ្រោះ" ប្រើទីតាំងរបស់អ្នកដែរឬទេ?',
    ),
    'gps_dialog_body': _k(
      'Your location helps find the nearest help and share it with responders.',
      'ទីតាំងរបស់អ្នកជួយរកជំនួយដែលនៅជិតបំផុត និងចែករំលែកជាមួយអ្នកសង្គ្រោះ។',
    ),
    'allow_while': _k('Allow While Using App', 'អនុញ្ញាតពេលកំពុងប្រើកម្មវិធី'),
    'allow_once': _k('Allow Once', 'អនុញ្ញាតម្តង'),
    'dont_allow': _k("Don't Allow", 'មិនអនុញ្ញាត'),

    // ── Navigation ───────────────────────────────────────────────────
    'nav_home': _k('SOS Home', 'ទំព័រដើម'),
    'nav_map': _k('Nearby Map', 'ផែនទីជិតខ្លួន'),
    'nav_safety': _k('Safety Tips', 'គន្លឹះសុវត្ថិភាព'),
    'nav_hotlines': _k('Hotlines', 'ខ្សែទូរស័ព្ទ'),

    // ── Home ─────────────────────────────────────────────────────────
    'gps_active': _k('GPS Active', 'ទីតាំងដំណើរការ'),
    'gps_off': _k('GPS Off', 'ទីតាំងបិទ'),
    'your_location': _k('YOUR LOCATION', 'ទីតាំងរបស់អ្នក'),
    'copy_location': _k('Copy Location', 'ចម្លងទីតាំង'),
    'view_map': _k('View Map', 'មើលផែនទី'),
    'location_copied': _k('Location copied', 'បានចម្លងទីតាំង'),
    'copied': _k('Copied', 'បានចម្លង'),
    'medical': _k('Medical', 'វេជ្ជសាស្ត្រ'),
    'hospital': _k('Hospital', 'មន្ទីរពេទ្យ'),
    'police': _k('Police', 'ប៉ូលិស'),
    'fire': _k('Fire', 'ពន្លត់អគ្គិភ័យ'),
    'sos_shortcut': _k('SOS', 'អាសន្ន'),
    'choose_khan': _k('Choose your Khan', 'ជ្រើសរើសខណ្ឌរបស់អ្នក'),
    'khan_word': _k('Khan', 'ខណ្ឌ'),

    // ── SOS call ─────────────────────────────────────────────────────
    'share': _k('Share', 'ចែករំលែក'),
    'alt_desk': _k('Alternate desk', 'ទូរស័ព្ទបន្ទាប់បន្សំ'),
    'send_message': _k('Send Message', 'ផ្ញើសារ'),
    'copy': _k('Copy', 'ចម្លង'),
    'address_copied': _k('Address copied', 'បានចម្លងអាសយដ្ឋាន'),
    'sos_sms_body': _k(
      'SOS! I need help. My location:',
      'អាសន្ន! ខ្ញុំត្រូវការជំនួយ។ ទីតាំងរបស់ខ្ញុំ៖',
    ),
    'tap_sos': _k('Tap SOS to call', 'ចុចប៊ូតុងអាសន្នដើម្បីហៅ'),

    // ── Outgoing call ────────────────────────────────────────────────
    'calling': _k('calling...', 'កំពុងហៅ...'),
    'mute': _k('mute', 'បិទសំឡេង'),
    'keypad': _k('keypad', 'ក្តារលេខ'),
    'speaker': _k('speaker', 'ឧបករណ៍ពង្រីកសំឡេង'),
    'add_call': _k('add call', 'បន្ថែមការហៅ'),
    'facetime': _k('FaceTime', 'ហៅវីដេអូ'),
    'contacts': _k('contacts', 'បញ្ជីទំនាក់ទំនង'),
    'read_location': _k('Read My Location', 'អានទីតាំងរបស់ខ្ញុំ'),

    // ── Map ──────────────────────────────────────────────────────────
    'search_hint': _k(
      'Search hospital, police, fire...',
      'ស្វែងរកមន្ទីរពេទ្យ ប៉ូលិស ពន្លត់អគ្គិភ័យ...',
    ),
    'all': _k('All', 'ទាំងអស់'),
    'hospitals': _k('Hospitals', 'មន្ទីរពេទ្យ'),
    'police_tab': _k('Police', 'ប៉ូលិស'),
    'fire_tab': _k('Fire', 'ពន្លត់អគ្គិភ័យ'),
    'nearby_hospitals': _k('Nearby Hospitals', 'មន្ទីរពេទ្យនៅជិត'),
    'nearby_police': _k('Nearby Police Stations', 'ប៉ុស្តិ៍ប៉ូលិសនៅជិត'),
    'nearby_fire': _k('Nearby Fire Stations', 'ស្ថានីយ៍ពន្លត់អគ្គិភ័យនៅជិត'),
    'results': _k('Search results', 'លទ្ធផលស្វែងរក'),
    'closest_first': _k('Closest first', 'ជិតបំផុតមុន'),
    'no_results': _k('No matching places', 'រកមិនឃើញទីតាំងដែលត្រូវគ្នា'),
    'pin_hospital': _k('Hospitals Emergency', 'មន្ទីរពេទ្យសង្គ្រោះបន្ទាន់'),
    'pin_police': _k('Police', 'ប៉ូលិស'),
    'pin_fire': _k('Fire Emergency', 'អគ្គិភ័យបន្ទាន់'),
    'tag_er': _k('24/7 ER', 'សង្គ្រោះ ២៤/៧'),
    'tag_police': _k('POLICE', 'ប៉ូលិស'),
    'tag_fire': _k('FIRE', 'អគ្គិភ័យ'),
    'recenter': _k('Recenter on my location', 'ត្រឡប់ទៅទីតាំងរបស់ខ្ញុំ'),
    'unit_km': _k('km', 'គ.ម'),
    'unit_min': _k('min', 'នាទី'),
    'unit_m': _k('m', 'ម៉ែត្រ'),
    'swipe_up': _k('Swipe up', 'អូសឡើងលើ'),
    'cat_medical': _k('Medical', 'ពេទ្យសង្គ្រោះបន្ទាន់'),
    'cat_police': _k('Police', 'ប៉ូលិសសង្គ្រោះ'),
    'cat_fire': _k('Fire & Rescue', 'អគ្គិភ័យ'),
    'pill_direct': _k('DIRECT {phone}', 'ផ្ទាល់ {phone}'),
    'pill_hotline': _k('HOTLINE {phone}', 'ខ្សែបន្ទាន់ {phone}'),

    // ── Emergency chat ───────────────────────────────────────────────
    'chat_connected': _k('Connected • {phone}', 'បានភ្ជាប់ • {phone}'),
    'chat_hint': _k('Message {phone}...', 'ផ្ញើសារទៅ {phone}...'),
    'chat_caption_hint': _k('Add a caption...', 'បន្ថែមចំណងជើង...'),
    'chip_gps': _k('📍 Send GPS', '📍 ផ្ញើទីតាំង'),
    'chip_ambulance': _k('🚑 Need Ambulance', '🚑 ត្រូវការរថយន្តសង្គ្រោះ'),
    'chip_bleeding': _k('🩸 Severe Bleeding', '🩸 ឈាមហូរខ្លាំង'),
    'chip_police': _k('🚓 Need Police', '🚓 ត្រូវការប៉ូលិស'),
    'msg_ambulance': _k(
      'I need an ambulance at my location.',
      'ខ្ញុំត្រូវការរថយន្តសង្គ្រោះនៅទីតាំងរបស់ខ្ញុំ។',
    ),
    'msg_bleeding': _k(
      'Severe bleeding — please hurry!',
      'ឈាមហូរខ្លាំង — សូមមកជាបន្ទាន់!',
    ),
    'msg_police': _k(
      'I need the police at my location.',
      'ខ្ញុំត្រូវការប៉ូលិសនៅទីតាំងរបស់ខ្ញុំ។',
    ),
    'st_sending': _k('Sending', 'កំពុងផ្ញើ'),
    'st_sent': _k('Sent', 'បានផ្ញើ'),
    'st_delivered': _k('Delivered', 'បានដល់'),
    'st_read': _k('Read', 'បានអាន'),
    'photo': _k('Photo', 'រូបថត'),
    'close_photo': _k('Close photo', 'បិទរូបថត'),
    'play_voice': _k('Play voice message', 'ចាក់សារសំឡេង'),
    'end_call': _k('End call', 'បញ្ចប់ការហៅ'),
    'toggle_list': _k('Toggle list', 'បើក/បិទបញ្ជី'),
    'switch_language': _k('Switch language', 'ប្តូរភាសា'),
    'live_location': _k('Live Location', 'ទីតាំងបន្តផ្ទាល់'),
    'send_my_location': _k('Send my location', 'ផ្ញើទីតាំងរបស់ខ្ញុំ'),
    'call_dispatch': _k('Call dispatch', 'ហៅមជ្ឈមណ្ឌលបញ្ជា'),
    'send': _k('Send', 'ផ្ញើ'),
    'cancel': _k('Cancel', 'បោះបង់'),
    'attach_photo': _k('Attach a photo', 'ភ្ជាប់រូបថត'),
    'attach_library': _k(
      'Choose from Photo Library',
      'ជ្រើសរើសពីបណ្ណាល័យរូបថត',
    ),
    'attach_camera': _k('Take Photo', 'ថតរូប'),
    'attach_demo': _k('Quick Demo Incident Photo', 'រូបថតឧបទ្ទវហេតុគំរូ'),
    'attach_demo_sub': _k(
      'Sample image — works without a camera or library',
      'រូបគំរូ — ប្រើបានដោយគ្មានកាមេរ៉ា',
    ),
    'photo_unavailable': _k(
      "Photos aren't available here. Try the demo photo.",
      'មិនអាចប្រើរូបថតនៅទីនេះបានទេ។ សាកល្បងរូបគំរូ។',
    ),
    'use_demo': _k('Use demo', 'ប្រើរូបគំរូ'),
    'remove_photo': _k('Remove photo', 'លុបរូបថត'),
    'record_voice': _k('Record voice message', 'ថតសារសំឡេង'),
    'send_voice': _k('Send voice message', 'ផ្ញើសារសំឡេង'),
    'pause_voice': _k('Pause voice message', 'ផ្អាកសារសំឡេង'),
    'photo_from_library': _k('Photo library', 'បណ្ណាល័យរូបថត'),
    'typing': _k('Dispatch is typing', 'មជ្ឈមណ្ឌលកំពុងវាយ'),
    'start_route': _k('Start Route', 'ចាប់ផ្តើមដំណើរ'),
    'call_now': _k('Call Now', 'ហៅឥឡូវនេះ'),
    'exit': _k('Exit', 'ចាកចេញ'),
    'details': _k('Details', 'ព័ត៌មានលម្អិត'),
    'close_sheet': _k('Close', 'បិទ'),
    'clear_search': _k('Clear search', 'សម្អាតការស្វែងរក'),
    'nav_head': _k(
      'Head {dir} on St. 598 toward {dest}',
      'ធ្វើដំណើរទៅទិស{dir} តាមផ្លូវ ៥៩៨ ឆ្ពោះទៅ {dest}',
    ),
    'dir_n': _k('north', 'ជើង'),
    'dir_ne': _k('northeast', 'ឦសាន'),
    'dir_e': _k('east', 'កើត'),
    'dir_se': _k('southeast', 'អាគ្នេយ៍'),
    'dir_s': _k('south', 'ត្បូង'),
    'dir_sw': _k('southwest', 'និរតី'),
    'dir_w': _k('west', 'លិច'),
    'dir_nw': _k('northwest', 'ពាយ័ព្យ'),

    // ── Safety ───────────────────────────────────────────────────────
    'safety': _k('Safety', 'សុវត្ថិភាព'),
    'what_happened': _k('What happened?', 'មានអ្វីកើតឡើង?'),
    'what_happened_sub': _k(
      "Tell us a little. We'll help you focus on what to do next.",
      'ប្រាប់យើងបន្តិច។ យើងនឹងជួយអ្នកផ្តោតលើអ្វីដែលត្រូវធ្វើបន្ទាប់។',
    ),
    'urgent_title': _k('Need urgent help?', 'ត្រូវការជំនួយបន្ទាន់?'),
    'urgent_body': _k(
      'Serious injury or immediate danger? Call local emergency services now.',
      'របួសធ្ងន់ធ្ងរ ឬគ្រោះថ្នាក់ភ្លាមៗ? សូមហៅសេវាសង្គ្រោះបន្ទាន់ក្នុងតំបន់ឥឡូវនេះ។',
    ),
    'urgent_body2': _k(
      "Danger or serious injury? Call local emergency services now. Follow the dispatcher's instructions.",
      'គ្រោះថ្នាក់ ឬរបួសធ្ងន់ធ្ងរ? សូមហៅសេវាសង្គ្រោះបន្ទាន់ក្នុងតំបន់ឥឡូវនេះ ហើយធ្វើតាមការណែនាំរបស់ប្រតិបត្តិករ។',
    ),
    'which_situation': _k(
      'Which best describes your situation?',
      'តើអ្វីពិពណ៌នាស្ថានភាពរបស់អ្នកបានល្អបំផុត?',
    ),
    'how_feeling': _k(
      'How are you feeling right now?',
      'ឥឡូវនេះអ្នកមានអារម្មណ៍យ៉ាងណា?',
    ),
    'feeling_hint': _k(
      "I've pulled over after a car accident. I'm shaking and don't know what to do.",
      'ខ្ញុំឈប់ឡានបន្ទាប់ពីគ្រោះថ្នាក់ចរាចរណ៍។ ខ្ញុំញ័រ ហើយមិនដឹងត្រូវធ្វើអ្វីទេ។',
    ),
    'show_tips': _k('Show my safety tips', 'បង្ហាញគន្លឹះសុវត្ថិភាពរបស់ខ្ញុំ'),
    'your_tips': _k('Your safety tips', 'គន្លឹះសុវត្ថិភាពរបស់អ្នក'),
    'for_situation': _k('FOR YOUR SITUATION', 'សម្រាប់ស្ថានភាពរបស់អ្នក'),
    'tips_calm': _k('Tips to stay calm', 'គន្លឹះរក្សាភាពស្ងប់ស្ងាត់'),
    'sit_car': _k('Car accident', 'គ្រោះថ្នាក់ចរាចរណ៍'),
    'sit_car_sub': _k(
      'Crash, collision or breakdown on the road',
      'ការបុក ឬបញ្ហារថយន្តលើផ្លូវ',
    ),
    'sit_fire': _k('Fire / Smoke', 'ភ្លើង / ផ្សែង'),
    'sit_fire_sub': _k('Fire or smoke nearby', 'មានភ្លើង ឬផ្សែងនៅជិត'),
    'sit_medical': _k('Medical', 'វេជ្ជសាស្ត្រ'),
    'sit_medical_sub': _k(
      'Someone is hurt or unwell',
      'មានអ្នករបួស ឬមិនស្រួលខ្លួន',
    ),

    // Tips — car accident
    'tip_breath_t': _k('Take a gentle breath', 'ដកដង្ហើមថ្នមៗ'),
    'tip_breath_b': _k(
      "If comfortable, breathe in gently and out slowly. Don't force it.",
      'ប្រសិនបើស្រួល សូមដកដង្ហើមចូលថ្នមៗ ហើយដកចេញយឺតៗ។ កុំបង្ខំខ្លួន។',
    ),
    'tip_car_around_t': _k('Check your surroundings', 'ពិនិត្យជុំវិញខ្លួន'),
    'tip_car_around_b': _k(
      'If safe, get clear of traffic. If you may be injured, stay still unless in immediate danger.',
      'ប្រសិនបើមានសុវត្ថិភាព សូមចៀសឱ្យឆ្ងាយពីចរាចរណ៍។ ប្រសិនបើអ្នកអាចរងរបួស សូមនៅស្ងៀម លើកលែងតែមានគ្រោះថ្នាក់ភ្លាមៗ។',
    ),
    'tip_trust_t': _k('Reach someone you trust', 'ទាក់ទងអ្នកដែលអ្នកទុកចិត្ត'),
    'tip_trust_b': _k(
      'Tell them where you are and what happened. Ask them to stay on the phone with you.',
      'ប្រាប់ពួកគេពីកន្លែងដែលអ្នកនៅ និងអ្វីដែលបានកើតឡើង។ សុំឱ្យពួកគេនៅលើទូរស័ព្ទជាមួយអ្នក។',
    ),
    // Tips — fire / smoke
    'tip_fire_out_t': _k('Get out and stay out', 'ចេញទៅក្រៅ ហើយកុំចូលវិញ'),
    'tip_fire_out_b': _k(
      "Leave the building right away. Stay low if there is smoke. Don't go back for belongings.",
      'ចាកចេញពីអគារភ្លាមៗ។ បើមានផ្សែង សូមឱ្យនៅទាប។ កុំត្រឡប់ទៅយកអីវ៉ាន់វិញ។',
    ),
    'tip_fire_call_t': _k(
      'Call from a safe place',
      'ហៅពីកន្លែងដែលមានសុវត្ថិភាព',
    ),
    'tip_fire_call_b': _k(
      'Once outside and safe, call the fire service (118) and share your location.',
      'នៅពេលចេញមកក្រៅដោយសុវត្ថិភាព សូមហៅសេវាពន្លត់អគ្គិភ័យ (១១៨) ហើយប្រាប់ទីតាំងរបស់អ្នក។',
    ),
    'tip_fire_away_t': _k('Keep others away', 'ឱ្យអ្នកដទៃនៅឆ្ងាយ'),
    'tip_fire_away_b': _k(
      'Warn people nearby and keep a safe distance from the building.',
      'ជូនដំណឹងដល់អ្នកនៅជិត ហើយរក្សាចម្ងាយសុវត្ថិភាពពីអគារ។',
    ),
    // Tips — medical
    'tip_med_stay_t': _k('Stay with the person', 'នៅជាមួយអ្នកដែលមានបញ្ហា'),
    'tip_med_stay_b': _k(
      "Keep them calm and comfortable. Don't move them if they may have a head, neck or back injury.",
      'ជួយឱ្យពួកគេស្ងប់ និងស្រួលខ្លួន។ កុំផ្លាស់ទីពួកគេ ប្រសិនបើអាចមានរបួសក្បាល ក ឬខ្នង។',
    ),
    'tip_med_call_t': _k('Follow the dispatcher', 'ធ្វើតាមប្រតិបត្តិករ'),
    'tip_med_call_b': _k(
      'When you call 119, answer their questions and follow their instructions.',
      'នៅពេលហៅលេខ ១១៩ សូមឆ្លើយសំណួររបស់ពួកគេ ហើយធ្វើតាមការណែនាំ។',
    ),

    // ── Hotlines ─────────────────────────────────────────────────────
    'hotlines_title': _k('Official hotlines', 'ខ្សែទូរស័ព្ទផ្លូវការ'),
    'quick_dial': _k('Quick dial', 'ហៅរហ័ស'),
    'ambulance': _k('Ambulance', 'រថយន្តសង្គ្រោះ'),
    'khan_directory': _k('Khans of Phnom Penh', 'ខណ្ឌនៃរាជធានីភ្នំពេញ'),
    'search_khan': _k('Search Khan...', 'ស្វែងរកខណ្ឌ...'),
    'khan_police': _k('Emergency police', 'នគរបាលសង្គ្រោះបន្ទាន់'),
  };

  /// Khmer numerals for `0-9` in Khmer mode (`012` → `០១២`); unchanged in
  /// English. Apply to every number *shown* (phones, distances, times) — the
  /// underlying data stays Latin so dialing/parsing keep working.
  static String digits(String s, AppLang lang) {
    if (lang != AppLang.km) return s;
    const kh = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    return s.replaceAllMapped(RegExp(r'[0-9]'), (m) => kh[int.parse(m[0]!)]);
  }

  static String of(String key, AppLang lang) =>
      _t[key]?[lang] ?? _t[key]?[AppLang.en] ?? key;
}
