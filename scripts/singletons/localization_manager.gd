extends Node

class_name LocalizationManager

signal language_changed(new_locale)

var current_locale = "en"

func _ready():
    # Load default translations or set initial locale
    set_locale("en") # Default to English

func set_locale(locale_code: String):
    if TranslationServer.has_locale(locale_code):
        TranslationServer.set_locale(locale_code)
        current_locale = locale_code
        emit_signal("language_changed", current_locale)
        print("Locale set to: %s" % current_locale)
    else:
        print("Warning: Locale %s not found." % locale_code)

func get_locale() -> String:
    return current_locale

func tr(message_key: String) -> String:
    # This function will use Godot's built-in translation system
    return TranslationServer.translate(message_key)
