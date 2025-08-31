import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "customField", "customInput"]

  connect() {
    // Check if we're editing and have a custom data source name
    const customInput = this.customInputTarget
    const hasCustomValue = customInput.value && customInput.value.trim() !== ""
    
    if (hasCustomValue) {
      // If there's a custom value, select "Other" and show the field
      const otherOption = Array.from(this.selectTarget.options).find(option => 
        option.text.toLowerCase() === "other"
      )
      if (otherOption) {
        this.selectTarget.value = otherOption.value
      }
    }
    
    this.toggle()
  }

  toggle() {
    const selectedOption = this.selectTarget.options[this.selectTarget.selectedIndex]
    const selectedText = selectedOption?.text
    
    if (selectedText && selectedText.toLowerCase() === "other") {
      this.customFieldTarget.classList.remove("hidden")
    } else {
      this.customFieldTarget.classList.add("hidden")
      // Clear the custom input when not using "Other"
      this.customInputTarget.value = ""
    }
  }
}