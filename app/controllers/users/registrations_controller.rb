module Users

  class RegistrationsController < Devise::RegistrationsController

    def create
      build_resource(sign_up_params)

      if resource.country.present? && resource.date_of_birth.present? &&
         resource.age < AgeGate.digital_consent_age_for(resource.country)
        self.resource = resource
        return render :ineligible, status: :unprocessable_entity
      end

      super
    end

  end

end
