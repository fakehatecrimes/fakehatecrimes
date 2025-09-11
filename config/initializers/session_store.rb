# Be sure to restart your server when you modify this file.

Fakehatecrimes::Application.config.session_store :cookie_store, key: '_fakehatecrimes_session'
Rails.application.config.action_dispatch.cookies_serializer = :hybrid

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Fakehatecrimes::Application.config.session_store :active_record_store
