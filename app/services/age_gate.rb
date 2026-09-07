module AgeGate

  PRIZE_DRAFT_MINIMUM_AGE = 18
  DIGITAL_CONSENT_DEFAULT_AGE = 16
  DIGITAL_CONSENT_OVERRIDES = { 'GB' => 13, 'BE' => 13, 'FR' => 15 }.freeze

  def self.digital_consent_age_for(country_code)
    DIGITAL_CONSENT_OVERRIDES.fetch(country_code, DIGITAL_CONSENT_DEFAULT_AGE)
  end

end
