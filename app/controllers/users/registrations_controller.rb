module Users

  class RegistrationsController < Devise::RegistrationsController

    REJECTION_COOLDOWN = 24.hours

    def new
      return render :ineligible if recently_rejected?

      super
    end

    def create
      return render :ineligible, status: :unprocessable_entity if recently_rejected?

      build_resource(sign_up_params)

      if age_gate_applies? && resource.age < AgeGate.digital_consent_age_for(resource.country)
        session[:age_gate_rejected_at] = Time.current.to_i
        return render :ineligible, status: :unprocessable_entity
      end

      super
    end

    private

    def age_gate_applies?
      resource.country.present? && resource.date_of_birth.present? &&
        resource.date_of_birth <= Date.current
    end

    def recently_rejected?
      rejected_at = session[:age_gate_rejected_at]
      rejected_at.present? && Time.zone.at(rejected_at) > REJECTION_COOLDOWN.ago
    end

  end

end
