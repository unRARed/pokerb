class Emailer
  CONFIG = {
    address: ENV['RBPKR_SMTP_HOST'],
    port: 587,
    domain: ENV['RBPKR_SMTP_DOMAIN'],
    user_name: ENV['RBPKR_SMTP_USERNAME'],
    password: ENV['RBPKR_SMTP_PASSWORD'],
    authentication: 'plain',
    enable_starttls_auto: true
  }

  def initialize(env = :development)
    Mail.defaults do
      case env
      when :development
        delivery_method(
          LetterOpener::DeliveryMethod,
          location: Dir.pwd + '/tmp/letter_opener'
        )
      when :test
        delivery_method(:test)
      else
        delivery_method(:smtp, CONFIG)
      end
    end
  end

  def send_activation_email(user)
    # User.save is supposed to trigger setting the
    # token, but doesn't seem to with Sinatra
    user.regenerate_email_confirmation_token
    email = Mail.new do
      part :content_type => "multipart/mixed" do |p1|
        p1.part :content_type => "multipart/related" do |p2|
          p2.part :content_type => "multipart/alternative",
            :content_disposition => "inline" do |p3|
            p3.part :content_type => "text/plain; charset=utf-8",
              :body => "Before using RbPkr, you " \
                "need to confirm your email address. Follow " \
                "this URL to activate your account: " \
                "#{RbPkr.server_url}/confirm" \
                "/#{user.email_confirmation_token}"
            p3.part :content_type => "text/html; charset=utf-8",
              :body => Tilt.new("views/email_confirmation.slim").
                render(self, url: "#{RbPkr.server_url}/confirm/" \
                  "#{user.email_confirmation_token}"
                )
          end
        end
      end
      from 'RbPkr <noreply@rbpkr.com>'
      to user.email
      subject 'Confirm your account at RbPkr.com'
    end
    email.deliver
  end
end
