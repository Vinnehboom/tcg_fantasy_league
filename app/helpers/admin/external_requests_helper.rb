module Admin

  module ExternalRequestsHelper

    def kind_label(external_request)
      I18n.t(external_request.kind, scope: %i[activerecord enums external_request kind])
    end

    def status_label(external_request)
      I18n.t(external_request.status, scope: %i[activerecord enums external_request status])
    end

  end

end
