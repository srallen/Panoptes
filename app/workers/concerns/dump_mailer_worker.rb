module DumpMailerWorker
  extend ActiveSupport::Concern

  included do
    set_callback :dump, :after, :send_email
  end

  def send_email
    return unless emails.present?
    mailer.perform_async(resource.id, resource.class.to_s.downcase, media_get_url, emails)
  end

  def mailer
    "#{dump_target.singularize}_data_mailer_worker".camelize.constantize
  end

  def emails
    if recipients = medium.try(:metadata).try(:[], "recipients")
      User.where(id: recipients).pluck(:email)
    else
      [resource.owner.email]
    end
  end

  def media_get_url(expires=24*60)
    medium.get_url(get_expires: expires)
  end
end
