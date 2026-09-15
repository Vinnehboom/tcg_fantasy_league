module DataSubjectRequestsHelper

  def data_subject_request_type_label(data_subject_request_type)
    I18n.t(data_subject_request_type, scope: %i[activerecord enums data_subject_request request_type])
  end

  def data_subject_request_status_label(data_subject_request_status)
    I18n.t(data_subject_request_status, scope: %i[activerecord enums data_subject_request status])
  end

end
