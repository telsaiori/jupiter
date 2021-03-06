module MetaTagHelper
  def set_meta(data = {})
    data = process_meta_data(data)
    set_meta_tags(data.merge(
                    reverse:   default_meta[:reverse],
                    separator: default_meta[:separator],
                    canonical: data[:og][:url]
    ))
  end

  def default_meta
    { title: "Jupiter@5FPRO",
      description: "Jupiter@5FPRO",
      keywords: "5FPRO",
      fb_app_id: "12341234",
      fb_admin_ids: "1234,123",
      separator: " | ",
      reverse: true,
      og_type: "website",
      site: "5FPRO",
      icon: [
        { href: ActionController::Base.helpers.asset_path('icon-100.png'), type: 'image/png' },
        { href: ActionController::Base.helpers.asset_path('icon-100.png'), type: 'image/png', rel: 'apple-touch-icon apple-touch-icon-precomposed' }
      ]
    }
  end

  private

  def process_meta_data(data)
    url = data[:url] || url_for(params.merge(host: Setting.host))
    data[:title] ||= default_meta[:title]
    data[:description] ||= default_meta[:description]
    data[:keywords] ||= default_meta[:keywords]
    data[:site] ||= default_meta[:site]
    data[:og] = {
      title:       (data[:title] || data[:site]),
      description: data[:description],
      url:         url,
      type:        data[:og_type] || default_meta[:og_type]
    }
    data[:fb] = {
      app_id: default_meta[:fb_app_id],
      admins: default_meta[:fb_admin_ids]
    }
    data[:og][:image] = data[:image] if data[:image]
    data[:icon] ||= default_meta[:icon]
    data
  end
end
