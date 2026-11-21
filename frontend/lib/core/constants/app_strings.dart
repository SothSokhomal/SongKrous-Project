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
    'phone_hint': _k('12 855 706', '១២ ៨៥៥ ៧០៦'),
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
    'nav_home': _k('Home', 'ទំព័រដើម'),
    'nav_map': _k('Map', 'ផែនទី'),
    'nav_safety': _k('Safety Tips', 'គន្លឹះសុវត្ថិភាព'),
    'nav_activity': _k('Activity', 'សកម្មភាព'),
    'nav_hotlines': _k('Hotline', 'ខ្សែទូរស័ព្ទ'),
    'nav_settings': _k('Settings', 'ការកំណត់'),

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

    // ── SOS call ─────────────────────────────────────────────────────
    'share': _k('Share', 'ចែករំលែក'),
    'alt_desk': _k('Alternate desk', 'ទូរស័ព្ទបន្ទាប់បន្សំ'),
    'send_message': _k('Send Message', 'ផ្ញើសារ'),
    'copy': _k('Copy', 'ចម្លង'),
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
    'closest_first': _k('Closest first', 'ជិតបំផុតមុន'),
    'no_results': _k('No matching places', 'រកមិនឃើញទីតាំងដែលត្រូវគ្នា'),
    'tag_er': _k('24/7 ER', 'សង្គ្រោះ ២៤/៧'),
    'tag_police': _k('POLICE', 'ប៉ូលិស'),
    'tag_fire': _k('FIRE', 'អគ្គិភ័យ'),
    'recenter': _k('Recenter on my location', 'ត្រឡប់ទៅទីតាំងរបស់ខ្ញុំ'),
    'unit_km': _k('km', 'គ.ម'),
    'unit_min': _k('min', 'នាទី'),
    'unit_m': _k('m', 'ម៉ែត្រ'),
    'swipe_up': _k('Swipe up', 'អូសឡើងលើ'),
    'cat_medical': _k('Hospital', 'មន្ទីរពេទ្យ'),
    'cat_police': _k('Police', 'ប៉ូលិស'),
    'cat_fire': _k('Fire', 'ពន្លត់អគ្គិភ័យ'),
    'trigger_sos': _k('EMERGENCY SOS', 'សង្គ្រោះបន្ទាន់'),

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
    // ── Delivery channel + OTP verification ──
    'sending_code': _k('Sending code...', 'កំពុងផ្ញើលេខកូដ...'),
    'phone_invalid': _k(
      'Please enter a valid phone number, or tap Skip for now',
      'សូមបញ្ចូលលេខទូរសព្ទឲ្យត្រឹមត្រូវ ឬចុច «រំលងសិន»',
    ),
    'demo_fill': _k(
      'Tap to auto-fill: {phone}',
      'ចុចដើម្បីបំពេញស្វ័យប្រវត្តិ៖ {phone}',
    ),
    'send_code': _k('Send Verification Code', 'ផ្ញើលេខកូដផ្ទៀងផ្ទាត់'),
    'ch_sms_card': _k('SMS Code', 'កូដតាមសារ'),
    'ch_wa_card': _k('WhatsApp', 'វ៉ាត់ស្អាប់'),
    'channel_sms': _k('SMS', 'សារ'),
    'channel_whatsapp': _k('WhatsApp', 'វ៉ាត់ស្អាប់'),
    'otp_title': _k('Verify your number', 'ផ្ទៀងផ្ទាត់លេខទូរសព្ទ'),
    'otp_sub': _k(
      'Enter the 6-digit code we sent via {channel} to',
      'បញ្ចូលលេខកូដ ៦ ខ្ទង់ ដែលយើងបានផ្ញើតាម{channel} ទៅកាន់',
    ),
    'otp_incomplete': _k(
      'Enter all 6 digits of the code',
      'សូមបញ្ចូលលេខកូដទាំង ៦ ខ្ទង់',
    ),
    'edit': _k('Edit', 'កែប្រែ'),
    'otp_invalid': _k(
      'Invalid code. Try 123456 or tap Resend.',
      'លេខកូដមិនត្រឹមត្រូវ។ សាកល្បង ១២៣៤៥៦ ឬចុចផ្ញើម្តងទៀត។',
    ),
    'otp_resend_in': _k(
      "Didn't get the code? Resend in {time}",
      'មិនទទួលបានលេខកូដ? ផ្ញើម្តងទៀតក្នុង {time}',
    ),
    'otp_resend_via': _k('Resend via {channel}', 'ផ្ញើម្តងទៀតតាម{channel}'),
    'otp_try_other': _k('Try {channel} instead', 'សាកល្បងតាម{channel}ជំនួសវិញ'),
    'otp_verify': _k('Verify & Continue', 'ផ្ទៀងផ្ទាត់ និងបន្ត'),
    'otp_verifying': _k('Verifying...', 'កំពុងផ្ទៀងផ្ទាត់...'),
    'otp_verified': _k('✓ Verified', '✓ បានផ្ទៀងផ្ទាត់'),
    'otp_banner_from': _k('From {channel}', 'ពី{channel}'),
    'otp_banner_msg': _k(
      'Your Songkrous code is {code}',
      'លេខកូដសង្គ្រោះរបស់អ្នកគឺ {code}',
    ),
    'otp_autofill': _k('Auto-Fill', 'បំពេញ'),
    'otp_digit': _k('Digit {n} of 6', 'ខ្ទង់ទី {n} នៃ ៦'),
    'otp_field': _k('6-digit verification code', 'លេខកូដផ្ទៀងផ្ទាត់ ៦ ខ្ទង់'),
    'call_failed': _k(
      "Couldn't open the phone app. Please dial the number yourself.",
      'មិនអាចបើកកម្មវិធីទូរសព្ទបានទេ។ សូមហៅលេខនេះដោយខ្លួនឯង។',
    ),
    'settings': _k('Settings', 'ការកំណត់'),
    'settings_account': _k('ACCOUNT', 'គណនី'),
    'settings_guest': _k('Guest mode', 'របៀបភ្ញៀវ'),
    'settings_guest_sub': _k(
      'Verify your number so responders can reach you.',
      'ផ្ទៀងផ្ទាត់លេខរបស់អ្នក ដើម្បីឱ្យអ្នកជួយទាក់ទងអ្នកបាន។',
    ),
    'settings_verify': _k('Verify my number', 'ផ្ទៀងផ្ទាត់លេខរបស់ខ្ញុំ'),
    'settings_verified': _k('Verified', 'បានផ្ទៀងផ្ទាត់'),
    'settings_language': _k('Language', 'ភាសា'),
    'settings_privacy': _k('PRIVACY', 'ឯកជនភាព'),
    'settings_location': _k('Location', 'ទីតាំង'),
    'settings_location_on': _k(
      'On — used only to find nearby help',
      'បើក — ប្រើសម្រាប់រកជំនួយនៅជិតប៉ុណ្ណោះ',
    ),
    'settings_location_off': _k(
      'Off — manual Khan selection active',
      'បិទ — កំពុងប្រើការជ្រើសរើសខណ្ឌដោយដៃ',
    ),
    'settings_location_denied': _k(
      'Location permission is off. Turn it on in your device Settings.',
      'ការអនុញ្ញាតទីតាំងត្រូវបានបិទ។ សូមបើកវានៅក្នុងការកំណត់ឧបករណ៍។',
    ),
    'settings_language_h': _k('LANGUAGE', 'ភាសា'),
    'profile_name': _k('Songkrous User', 'អ្នកប្រើសង្គ្រោះ'),
    'profile_set_photo': _k('Set New Photo', 'ផ្លាស់ប្តូររូបភាព'),
    'profile_photo_title': _k('Profile Photo', 'រូបភាពប្រូហ្វាល'),
    'photo_take': _k('Take Photo', 'ថតរូប'),
    'photo_gallery': _k('Choose from Gallery', 'ជ្រើសរើសពីវិចិត្រសាល'),
    'photo_styles': _k('Choose Avatar Style', 'ជ្រើសរើសរចនាប័ទ្មរូបតំណាង'),
    'photo_styles_sub': _k('Quick demo', 'សាកល្បងរហ័ស'),
    'photo_remove': _k('Remove Photo', 'លុបរូបភាព'),
    'photo_change': _k('Change Photo', 'ផ្លាស់ប្តូររូបភាព'),
    'photo_preview_hint': _k(
      'Pinch to zoom, drag to move',
      'ច្បិចដើម្បីពង្រីក អូសដើម្បីរំកិល',
    ),
    'photo_set_profile': _k('Set Profile Photo ✓', 'កំណត់រូបភាពប្រូហ្វាល ✓'),
    'avatar_unavailable': _k(
      "Camera isn't available here. Try the gallery or pick an avatar style.",
      'មិនអាចប្រើកាមេរ៉ានៅទីនេះបានទេ។ សូមសាកល្បងវិចិត្រសាល ឬជ្រើសរើសរចនាប័ទ្មរូបតំណាង។',
    ),
    'avatar_style_n': _k('Avatar style {n}', 'រចនាប័ទ្មរូបតំណាង {n}'),
    'settings_about': _k('ABOUT', 'អំពី'),
    'settings_version': _k('Version {v}', 'កំណែ {v}'),
    'settings_prototype': _k(
      'Prototype build. Your number and messages stay on this device.',
      'កំណែសាកល្បង។ លេខ និងសាររបស់អ្នកស្ថិតនៅលើឧបករណ៍នេះប៉ុណ្ណោះ។',
    ),
    'settings_logout': _k('Log out', 'ចាកចេញ'),
    'settings_logout_title': _k('Log out?', 'ចាកចេញមែនទេ?'),
    'settings_logout_body': _k(
      'Your number and chat history on this device will be cleared.',
      'លេខ និងប្រវត្តិសន្ទនានៅលើឧបករណ៍នេះនឹងត្រូវលុប។',
    ),
    'settings_logged_out': _k('You are logged out.', 'អ្នកបានចាកចេញហើយ។'),
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
    'photo_from_library': _k('Photo library', 'បណ្ណាល័យរូបថត'),
    'typing': _k('Dispatch is typing', 'មជ្ឈមណ្ឌលកំពុងវាយ'),
    'directions': _k('Directions', 'ទិសដៅ'),
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
    'safety_title': _k('First Aid & Safety', 'ការសង្គ្រោះបឋម និងសុវត្ថិភាព'),
    'safety_hub_sub': _k(
      'Tap any emergency guide for immediate step-by-step instructions.',
      'ចុចលើការណែនាំសង្គ្រោះបន្ទាន់ណាមួយ សម្រាប់ជំហានអនុវត្តភ្លាមៗ។',
    ),
    'safety_search_hint': _k('Search first aid guides...', 'ស្វែងរកការណែនាំសង្គ្រោះបឋម...'),
    'filter_all': _k('All', 'ទាំងអស់'),
    'filter_medical': _k('Medical', 'វេជ្ជសាស្ត្រ'),
    'filter_trauma': _k('Trauma', 'របួសធ្ងន់'),
    'filter_rescue': _k('Rescue', 'ជួយសង្គ្រោះ'),
    'filter_no_results': _k('No matching guides found', 'រកមិនឃើញការណែនាំដែលត្រូវគ្នាទេ'),
    'step_progress': _k('{done} of {total} steps completed', 'បានបំពេញ {done} នៃ {total} ជំហាន'),
    'step_count_label': _k('{n} Steps', '{n} ជំហាន'),
    'step_n_label': _k('STEP {n}', 'ជំហាន {n}'),
    'red_cross_reference': _k(
      'Reference: Standard Red Cross First Aid & Adult CPR Guidelines',
      'ប្រភព៖ គោលការណ៍ណែនាំសង្គ្រោះបឋម និង CPR របស់កាកបាទក្រហម',
    ),
    'call_emergency_now': _k('Call Emergency', 'ហៅសង្គ្រោះបន្ទាន់'),
    'quick_call_ambulance': _k('Call 119 Ambulance', 'ហៅ ១១៩ រថយន្តសង្គ្រោះ'),
    'quick_call_police': _k('Call 117 Police', 'ហៅ ១១៧ ប៉ូលិស'),
    'quick_call_fire': _k('Call 118 Fire Service', 'ហៅ ១១៨ ពន្លត់អគ្គិភ័យ'),
    'mark_done': _k('Completed', 'បានរួចរាល់'),

    // Category 1: Bleeding Control
    'cat_bleeding': _k('Bleeding Control', 'ការទប់ឈាមហូរ'),
    'cat_bleeding_sub': _k(
      'Direct pressure, wound care & tourniquets',
      'សង្កត់ផ្ទាល់ ថែទាំរបួស និងខ្សែរឹតទប់ឈាម',
    ),
    'cat_bleeding_over': _k(
      'Severe bleeding requires immediate, firm pressure to prevent life-threatening blood loss and shock.',
      'ការហូរឈាមធ្ងន់ធ្ងរតម្រូវឱ្យមានការសង្កត់ជាបន្ទាន់ ដើម្បីការពារកុំឱ្យបាត់បង់ឈាម និងខ្យល់គរ។',
    ),
    'bleed_s1_t': _k('Ensure Scene Safety & Use PPE', 'ពិនិត្យសុវត្ថិភាពទីតាំង និងពាក់ស្រោមដៃ'),
    'bleed_s1_b': _k(
      'Assess the surroundings for hazards and put on disposable protective gloves, if available.',
      'វាយតម្លៃជុំវិញរកមើលគ្រោះថ្នាក់ និងពាក់ស្រោមដៃការពារ ប្រសិនបើមាន។',
    ),
    'bleed_s2_t': _k('Call Emergency Services', 'ហៅសេវាសង្គ្រោះបន្ទាន់'),
    'bleed_s2_b': _k(
      'If bleeding is severe, immediately instruct a bystander to call local emergency medical services (119).',
      'ប្រសិនបើហូរឈាមខ្លាំង សូមប្រាប់អ្នកនៅជិតឱ្យហៅសេវាសង្គ្រោះបន្ទាន់ (១១៩) ភ្លាមៗ។',
    ),
    'bleed_s3_t': _k('Apply Direct Pressure', 'សង្កត់ដោយផ្ទាល់លើមុខរបួស'),
    'bleed_s3_b': _k(
      'Place a clean cloth, sterile gauze, or bandage directly over the wound and apply firm, continuous pressure until the bleeding stops. Do not remove the cloth or dressing in direct contact with the wound.',
      'ដាក់ក្រណាត់ស្អាត បង់រុំ ឬមារៈបង់រុំស្អាតពីលើមុខរបួស ហើយសង្កត់ឱ្យជាប់រហូតដល់ឈាមឈប់ហូរ។ កុំដកក្រណាត់ដែលប៉ះមុខរបួសចេញ។',
    ),
    'bleed_s4_t': _k('Apply a Tourniquet (If Necessary)', 'ប្រើខ្សែរឹតទប់ឈាម (បើចាំបាច់)'),
    'bleed_s4_b': _k(
      'For life-threatening bleeding from an arm or leg, apply a tourniquet if one is available and you are trained in its proper use. Continue monitoring and caring for the casualty until emergency responders arrive.',
      'ចំពោះការហូរឈាមគំរាមកំហែងដល់អាយុជីវិតពីដៃ ឬជើង សូមប្រើខ្សែរឹតទប់ឈាម ប្រសិនបើមាន និងចេះប្រើប្រាស់ត្រឹមត្រូវ។ បន្តតាមដានរហូតដល់ក្រុមសង្គ្រោះមកដល់។',
    ),

    // Category 2: Adult CPR
    'cat_cpr': _k('Adult CPR', 'ចលនាបេះដូង និងដង្ហើមសិប្បនិម្មិត (CPR)'),
    'cat_cpr_sub': _k(
      'Chest compressions & rescue breaths',
      'ការសង្កត់ទ្រូង និងការផ្លុំខ្យល់ដង្ហើម',
    ),
    'cat_cpr_over': _k(
      'CPR combines chest compressions and rescue breaths to maintain circulation and oxygenation for an individual who is unresponsive and not breathing normally.',
      'CPR រួមបញ្ចូលការសង្កត់ទ្រូង និងការផ្លុំខ្យល់ ដើម្បីរក្សាចរន្តឈាម និងអុកស៊ីសែន សម្រាប់អ្នកដែលមិនដឹងខ្លួន និងមិនដកដង្ហើមធម្មតា។',
    ),
    'cpr_s1_t': _k('Verify Scene Safety', 'ពិនិត្យសុវត្ថិភាពទីតាំង'),
    'cpr_s1_b': _k(
      'Ensure the environment is safe before approaching the casualty.',
      'ត្រូវប្រាកដថាបរិស្ថានជុំវិញមានសុវត្ថិភាព មុនពេលចូលទៅជិតជនរងគ្រោះ។',
    ),
    'cpr_s2_t': _k('Check Responsiveness & Breathing', 'ពិនិត្យការឆ្លើយតប និងការដកដង្ហើម'),
    'cpr_s2_b': _k(
      'Tap the person’s shoulder gently and shout to check for a response. Simultaneously assess breathing for no more than 10 seconds. Occasional gasping (agonal breaths) is not normal breathing.',
      'ទះស្មារបស់ជនរងគ្រោះថ្នមៗ និងស្រែកសួរ។ ពិនិត្យការដកដង្ហើមមិនលើសពី ១០ វិនាទី។ ការដកដង្ហើមដង្ហក់ មិនមែនជាការដកដង្ហើមធម្មតាទេ។',
    ),
    'cpr_s3_t': _k('Activate Emergency Response & Retrieve AED', 'ហៅសង្គ្រោះបន្ទាន់ និងរកម៉ាស៊ីន AED'),
    'cpr_s3_b': _k(
      'Call emergency medical services (119) immediately, place your phone on speaker mode, and ask a bystander to locate and bring an Automated External Defibrillator (AED).',
      'ហៅសេវាសង្គ្រោះបន្ទាន់ (១១៩) ភ្លាមៗ បើកឧបករណ៍បំពងសំឡេងទូរសព្ទ ហើយប្រាប់អ្នកនៅជិតឱ្យរកម៉ាស៊ីន AED។',
    ),
    'cpr_s4_t': _k('Position the Casualty & Hands', 'រៀបចំទីតាំងជនរងគ្រោះ និងដៃ'),
    'cpr_s4_b': _k(
      'Place the individual flat on their back on a firm, level surface. Place the heel of one hand in the center of the chest (lower half of the breastbone) and place your other hand directly on top, interlocking your fingers.',
      'ដាក់ជនរងគ្រោះឱ្យដេកផ្ងារលើផ្ទៃរាបស្មើ និងរឹងមាំ។ ដាក់បាតដៃម្ខាងនៅចំកណ្តាលទ្រូង ហើយដាក់ដៃម្ខាងទៀតពីលើ ដោយត្របាក់ម្រាមដៃចូលគ្នា។',
    ),
    'cpr_s5_t': _k('Deliver 30 Chest Compressions', 'សង្កត់ទ្រូង ៣០ ដង'),
    'cpr_s5_b': _k(
      'Perform 30 chest compressions at a rate of 100 to 120 compressions per minute, pushing to a depth of approximately 5 to 6 cm (2 to 2.4 inches). Allow the chest to fully recoil after each compression.',
      'សង្កត់ទ្រូង ៣០ ដង ក្នុងល្បឿនពី ១០០ ទៅ ១២០ ដងក្នុងមួយនាទី ជម្រៅប្រហែល ៥ ទៅ ៦ ស.ម។ ទុកឱ្យទ្រូងងើបឡើងវិញពេញលេញបន្ទាប់ពីការសង្កត់នីមួយៗ។',
    ),
    'cpr_s6_t': _k('Deliver 2 Rescue Breaths', 'ផ្លុំខ្យល់ដង្ហើម ២ ដង'),
    'cpr_s6_b': _k(
      'If you are trained and able, open the airway using the head-tilt, chin-lift maneuver and deliver 2 rescue breaths into the mouth, watching for visible chest rise. If you are untrained or unable to give rescue breaths, perform Hands-Only CPR (continuous chest compressions).',
      'ប្រសិនបើអ្នកបានទទួលការបណ្តុះបណ្តាល សូមងើយក្បាល និងលើកចង្កាជនរងគ្រោះ រួចផ្លុំខ្យល់ ២ ដង ដោយសង្កេតមើលទ្រូងឡើង។ ប្រសិនបើមិនចេះផ្លុំ សូមធ្វើតែការសង្កត់ទ្រូងជាប់រហូត។',
    ),
    'cpr_s7_t': _k('Continue Cycles & Use AED', 'បន្តវដ្ត CPR និងប្រើម៉ាស៊ីន AED'),
    'cpr_s7_b': _k(
      'Continue CPR cycles of 30 compressions and 2 breaths until the person shows signs of life, an AED arrives and is ready to analyze, or professional emergency responders take over.',
      'បន្តវដ្ត ៣០ ដង និងផ្លុំ ២ ដង រហូតដល់ជនរងគ្រោះដឹងខ្លួន ម៉ាស៊ីន AED មកដល់ ឬក្រុមសង្គ្រោះបន្ទាន់មកទទួលខុសត្រូវ។',
    ),

    // Category 3: Drowning
    'cat_drowning': _k('Drowning', 'ការលង់ទឹក'),
    'cat_drowning_sub': _k(
      'Water rescue, resuscitation & recovery',
      'ការជួយសង្គ្រោះពីទឹក ការសង្គ្រោះបឋម និងការថែទាំ',
    ),
    'cat_drowning_over': _k(
      'Swift action is vital in drowning cases. Prioritize rescuer safety and immediately restore oxygenation to the brain.',
      'សកម្មភាពរហ័សមានសារៈសំខាន់ណាស់ក្នុងការលង់ទឹក។ គិតគូរពីសុវត្ថិភាពអ្នកជួយជាចម្បង និងផ្តល់អុកស៊ីសែនដល់ខួរក្បាលជាបន្ទាន់។',
    ),
    'drown_s1_t': _k('Ensure Scene Safety & Call for Help', 'ពិនិត្យសុវត្ថិភាព និងហៅរកជំនួយ'),
    'drown_s1_b': _k(
      'Call emergency services immediately. Do not enter dangerous water unless trained; throw a flotation device or extend a branch/pole if possible.',
      'ហៅសេវាសង្គ្រោះបន្ទាន់ភ្លាមៗ។ កុំចុះទឹកគ្រោះថ្នាក់បើគ្មានការបណ្តុះបណ្តាល ចូរគប់ពោង ឬលយឈើ/បង្គោលឱ្យតោង។',
    ),
    'drown_s2_t': _k('Remove from Water Safely', 'ស្រង់ចេញពីទឹកដោយសុវត្ថិភាព'),
    'drown_s2_b': _k(
      'Bring the person to a dry, safe, flat surface as quickly as possible without endangering yourself.',
      'នាំជនរងគ្រោះទៅកាន់កន្លែងស្ងួត មានសុវត្ថិភាព និងរាបស្មើឱ្យបានលឿនតាមដែលអាចធ្វើទៅបាន។',
    ),
    'drown_s3_t': _k('Check Responsiveness & Breathing', 'ពិនិត្យការដឹងខ្លួន និងការដកដង្ហើម'),
    'drown_s3_b': _k(
      'Check if responsive and assess breathing for no more than 10 seconds. If not breathing normally, begin resuscitation immediately.',
      'ពិនិត្យការឆ្លើយតប និងដង្ហើមមិនលើសពី ១០ វិនាទី។ ប្រសិនបើមិនដកដង្ហើមធម្មតា ចាប់ផ្តើមសង្គ្រោះបន្ទាន់ភ្លាមៗ។',
    ),
    'drown_s4_t': _k('Deliver 5 Initial Rescue Breaths & CPR', 'ផ្លុំខ្យល់ ៥ ដងដំបូង និងធ្វើ CPR'),
    'drown_s4_b': _k(
      'For drowning casualties, open the airway and give 5 initial rescue breaths. If unresponsive, immediately begin 30 chest compressions followed by 2 rescue breaths.',
      'សម្រាប់ជនរងគ្រោះលង់ទឹក សូមបើកផ្លូវដង្ហើម ហើយផ្លុំខ្យល់ ៥ ដងដំបូង។ ប្រសិនបើនៅមិនដឹងខ្លួន ចាប់ផ្តើមសង្កត់ទ្រូង ៣០ ដង និងផ្លុំ ២ ដង។',
    ),
    'drown_s5_t': _k('Continue CPR & Prevent Hypothermia', 'បន្ត CPR និងការពារការចុះត្រជាក់ខ្លាំង'),
    'drown_s5_b': _k(
      'Continue CPR cycles until professional help arrives or the person revives. Remove wet clothes and cover with dry blankets.',
      'បន្តវដ្ត CPR រហូតដល់ជំនួយមកដល់ ឬជនរងគ្រោះដឹងខ្លួន។ ដោះសំលៀកបំពាក់សើមចេញ ហើយដណ្តប់ភួយស្ងួត។',
    ),

    // Category 4: Fainting
    'cat_fainting': _k('Fainting (Syncope)', 'ការសន្លប់ / ខ្យល់គរ'),
    'cat_fainting_sub': _k(
      'Positioning, airflow & recovery care',
      'ការតម្រង់ទីតាំង ខ្យល់អាកាស និងការថែទាំ',
    ),
    'cat_fainting_over': _k(
      'Fainting is a temporary loss of consciousness caused by a brief drop in blood flow to the brain.',
      'ការសន្លប់ ឬខ្យល់គរ គឺជាការបាត់បង់ស្មារតីបណ្តោះអាសន្ន ដែលបណ្តាលមកពីការថយចុះនៃលំហូរឈាមទៅកាន់ខួរក្បាល។',
    ),
    'faint_s1_t': _k('Position on Back & Elevate Legs', 'ឱ្យដេកផ្ងារ និងលើកជើងឡើង'),
    'faint_s1_b': _k(
      'Lay the person flat on their back and elevate legs about 12 inches (30 cm) to restore blood flow to the brain.',
      'ឱ្យជនរងគ្រោះដេកផ្ងាររាបស្មើ ហើយលើកជើងឡើងប្រហែល ៣០ ស.ម ដើម្បីជួយឱ្យឈាមរត់ទៅខួរក្បាល។',
    ),
    'faint_s2_t': _k('Loosen Tight Clothing', 'បន្ធូរសម្លៀកបំពាក់តឹង'),
    'faint_s2_b': _k(
      'Loosen collars, belts, or tight waistbands to support normal breathing and blood circulation.',
      'បន្ធូរកអាវ ខ្សែក្រវាត់ ឬសម្លៀកបំពាក់ដែលតឹង ដើម្បីជួយសម្រួលការដកដង្ហើម និងចរន្តឈាម។',
    ),
    'faint_s3_t': _k('Check Airway & Ensure Fresh Air', 'ពិនិត្យផ្លូវដង្ហើម និងផ្តល់ខ្យល់អាកាស'),
    'faint_s3_b': _k(
      'Ensure the airway remains open and clear. Fan the person or move them to a well-ventilated, shaded area.',
      'ត្រូវប្រាកដថាផ្លូវដង្ហើមចំហ និងស្រឡះ។ បក់ផ្លិត ឬផ្លាស់ទីទៅកន្លែងដែលមានខ្យល់ចេញចូលល្អ និងម្លប់។',
    ),
    'faint_s4_t': _k('Check Responsiveness', 'ពិនិត្យការដឹងខ្លួន'),
    'faint_s4_b': _k(
      'If the person does not regain consciousness within 1 minute, immediately call emergency medical services (119).',
      'ប្រសិនបើជនរងគ្រោះមិនដឹងខ្លួនឡើងវិញក្នុងរយៈពេល ១ នាទី សូមហៅសេវាសង្គ្រោះបន្ទាន់ (១១៩) ភ្លាមៗ។',
    ),
    'faint_s5_t': _k('Post-Fainting Recovery Care', 'ការថែទាំក្រោយដឹងខ្លួន'),
    'faint_s5_b': _k(
      'Keep the person lying down for several minutes after waking. Do not let them stand up rapidly. Offer sips of water only after they are fully alert.',
      'ឱ្យជនរងគ្រោះដេកនៅស្ងៀមពីរបីនាទីបន្ទាប់ពីដឹងខ្លួន។ កុំឱ្យក្រោកឈរភ្លាមៗ។ ឱ្យផឹកទឹកតិចៗនៅពេលដឹងខ្លួនច្បាស់។',
    ),

    // Category 5: Fire / Smoke
    'cat_fire_over': _k(
      'In building fires, smoke and toxic fumes spread faster than flames. Immediate evacuation is paramount.',
      'ក្នុងករណីអគ្គិភ័យ ផ្សែងពុលរាលដាលលឿនជាងភ្លើង។ ការជម្លៀសចេញភ្លាមៗជាអាទិភាពខ្ពស់បំផុត។',
    ),
    'fire_s1_t': _k('Evacuate Immediately', 'ជម្លៀសចេញជាបន្ទាន់'),
    'fire_s1_b': _k(
      'Leave the building immediately using the nearest marked exit or fire stairwell. Do not use elevators.',
      'ចាកចេញពីអគារភ្លាមៗតាមច្រកចេញដែលជិតបំផុត ឬជណ្តើរភ្លើង។ កុំប្រើជណ្តើរយន្ត។',
    ),
    'fire_s2_t': _k('Stay Low Under Smoke', 'បន្ទាបខ្លួនក្រោមផ្សែង'),
    'fire_s2_b': _k(
      'Toxic smoke and heated gases rise. Crawl low under the smoke where the air is cleanest and coolest.',
      'ផ្សែងពុល និងកម្តៅហុយឡើងលើ។ ចូរវារឱ្យទាបនៅក្រោមផ្សែង ដែលជាកន្លែងខ្យល់ស្អាត និងត្រជាក់ជាង។',
    ),
    'fire_s3_t': _k('Test Doors Before Opening', 'ស្ទាបទ្វារមុននឹងបើក'),
    'fire_s3_b': _k(
      'Feel the door handle with the back of your hand. If hot to the touch, do not open; seek an alternative escape route.',
      'ស្ទាបដៃទ្វារដោយខ្នងដៃ។ បើក្តៅ កុំបើក ចូរស្វែងរកច្រកចេញផ្សេងទៀត។',
    ),
    'fire_s4_t': _k('Call Emergency Fire Service & Stay Outside', 'ហៅពន្លត់អគ្គិភ័យ និងនៅខាងក្រៅ'),
    'fire_s4_b': _k(
      'Once safely outside at a designated assembly area, call 118 immediately. Never re-enter a burning building.',
      'ពេលចេញមកក្រៅដោយសុវត្ថិភាព សូមហៅលេខ ១១៨ ភ្លាមៗ។ ដាច់ខាតកុំត្រឡប់ចូលក្នុងអគារដែលកំពុងឆេះវិញ។',
    ),

    // Category 6: Car Accident
    'cat_car_over': _k(
      'Roadside emergencies require hazard prevention before attending to victims to avoid secondary collisions.',
      'គ្រោះថ្នាក់ចរាចរណ៍តម្រូវឱ្យមានការការពារគ្រោះថ្នាក់បន្ថែម មុនពេលជួយជនរងគ្រោះ។',
    ),
    'car_s1_t': _k('Secure the Scene & Turn Off Ignition', 'ការពារទីតាំង និងពន្លត់ម៉ាស៊ីន'),
    'car_s1_b': _k(
      'If safe, pull over to the shoulder, turn on emergency hazard flashers, and turn off the engine ignition to prevent fires.',
      'បើមានសុវត្ថិភាព សូមឈប់អែបខាង បើកភ្លើងសញ្ញាអាសន្ន និងពន្លត់ម៉ាស៊ីនរថយន្តដើម្បីការពារភ្លើងឆេះ។',
    ),
    'car_s2_t': _k('Call Emergency Services', 'ហៅសេវាសង្គ្រោះបន្ទាន់'),
    'car_s2_b': _k(
      'Call 117 (Police) or 119 (Ambulance). Report the exact location, number of injured individuals, and vehicle count.',
      'ហៅលេខ ១១៧ (ប៉ូលិស) ឬ ១១៩ (រថយន្តសង្គ្រោះ)។ ប្រាប់ទីតាំងជាក់លាក់ ចំនួនអ្នករបួស និងយានយន្ត។',
    ),
    'car_s3_t': _k('Check for Injuries & Do Not Move Victims', 'ពិនិត្យរបួស និងកុំផ្លាស់ទីអ្នករបួស'),
    'car_s3_b': _k(
      'Check all occupants for responsiveness and bleeding. Do NOT move seriously injured victims unless there is imminent danger of explosion or fire.',
      'ពិនិត្យអ្នករបួសទាំងអស់។ កុំផ្លាស់ទីអ្នករងរបួសធ្ងន់ លើកលែងតែមានគ្រោះថ្នាក់ផ្ទុះ ឬឆេះភ្លាមៗ។',
    ),
    'car_s4_t': _k('Control Bleeding & Keep Warm', 'ទប់ការហូរឈាម និងរក្សាកម្តៅ'),
    'car_s4_b': _k(
      'Apply firm direct pressure to severe wounds with a clean cloth. Keep casualties calm and warm until emergency units arrive.',
      'សង្កត់ផ្ទាល់លើមុខរបួសធ្ងន់ដោយក្រណាត់ស្អាត។ ជួយឱ្យជនរងគ្រោះស្ងប់ចិត្ត និងកក់ក្តៅ រហូតដល់ក្រុមសង្គ្រោះមកដល់។',
    ),

    // Legacy and common situation keys
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
    'khan_directory': _k('Khans of Phnom Penh', 'ខណ្ឌនៃរាជធានីភ្នំពេញ'),
    'search_khan': _k('Search Khan...', 'ស្វែងរកខណ្ឌ...'),
    'khan_police': _k('Emergency police', 'នគរបាលសង្គ្រោះបន្ទាន់'),

    // ── Activity ─────────────────────────────────────────────────────
    'recent_activity': _k('Recent Activity', 'សកម្មភាពថ្មីៗ'),
    'activity_subtitle': _k(
      'Past emergency calls & SOS dispatches',
      'ការហៅសង្គ្រោះបន្ទាន់ និងប្រវត្តិ SOS',
    ),
    'no_activity': _k(
      'No activity in this category',
      'គ្មានសកម្មភាពក្នុងប្រភេទនេះទេ',
    ),
    'filter_hospital': _k('Hospital', 'មន្ទីរពេទ្យ'),
    'filter_police': _k('Police', 'ប៉ូលិស'),
    'filter_fire': _k('Fire Station', 'ពន្លត់អគ្គិភ័យ'),
    'filter_sos': _k('SOS', 'SOS'),
    'status_completed': _k('Completed', 'បានបញ្ចប់'),
    'status_dispatched': _k('Dispatched', 'បានបញ្ជូន'),
    'status_connected': _k('Connected', 'បានភ្ជាប់'),
    'incident_id': _k('Incident ID', 'លេខសម្គាល់ហេតុការណ៍'),
    'incident_id_copied': _k(
      'Incident ID copied to clipboard',
      'បានចម្លងលេខសម្គាល់ហេតុការណ៍',
    ),
    'response_rating': _k('Response rating', 'ការវាយតម្លៃការឆ្លើយតប'),
    'call_dispatch_info': _k(
      'Call & dispatch info',
      'ព័ត៌មានការហៅ និងបញ្ជូន',
    ),
    'call_mode': _k('Call mode', 'ទម្រង់ការហៅ'),
    'priority': _k('Priority', 'កម្រិតអាទិភាព'),
    'profile': _k('Profile', 'កម្រងព័ត៌មាន'),
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
