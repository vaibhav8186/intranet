Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, GOOGLE_API_CLIENT_ID, GOOGLE_API_CLIENT_SECRET,
    {
      :name => "google",
      provider_ignores_state: true,
      :scope => "email, profile",
      :prompt => "select_account",
      :image_aspect_ratio => "square",
      :image_size => 50
    }
end

