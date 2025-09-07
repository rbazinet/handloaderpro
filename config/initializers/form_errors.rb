# Add error messages inline after form fields

ActionView::Base.field_error_proc = proc do |html_tag, instance|
  html = ""

  form_fields = %w[input select textarea trix-editor]

  # Elements that can't have a border
  ignored_input_types = %w[checkbox hidden]
  
  # Fields that should not show inline errors (only in alert at top)
  no_inline_error_fields = %w[loaded_at]

  Nokogiri::HTML::DocumentFragment.parse(html_tag).children.each do |element|
    field_name = instance.send(:sanitized_method_name)
    
    html += if form_fields.include?(element.node_name) && ignored_input_types.exclude?(element.get_attribute("type")) && no_inline_error_fields.exclude?(field_name)
      element.add_class("error")

      errors = instance.error_message.to_sentence

      <<~HTML
        #{element}
        <p class="form-hint error">#{errors}</p>
      HTML
    elsif form_fields.include?(element.node_name) && ignored_input_types.exclude?(element.get_attribute("type"))
      # Still add error class for styling, but no inline message
      element.add_class("error")
      element.to_s
    else
      element.to_s
    end
  end

  html.html_safe
end
