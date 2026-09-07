module CountriesHelper

  COUNTRY_OPTIONS = ISO3166::Country.all_names_with_codes.freeze

  def country_options
    COUNTRY_OPTIONS
  end

end
