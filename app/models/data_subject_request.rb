class DataSubjectRequest < ApplicationRecord

  belongs_to :player

  enum request_type: { erase_or_object: 0 }
  enum status: { queued: 0, actioned: 1 }

  validates :request_type, presence: true
  validates :status, presence: true
  validate :contact_email_or_identity_proof_present

  def mark_actioned!
    transaction do
      update!(status: :actioned, actioned_at: Time.current)
      player.update!(suppressed_at: Time.current) unless player.suppressed?
      true
    end
  end

  private

  def contact_email_or_identity_proof_present
    return if contact_email.present? || identity_proof.present?

    errors.add(:base, :contact_email_or_identity_proof_required)
  end

end
