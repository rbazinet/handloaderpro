import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cartridgeType", "cartridge", "primerType", "bulletWeight", "bullet", "powder"]
  static values = { cartridges: Array, primerTypes: Array, bullets: Array, bulletWeights: Array, powders: Array }

  connect() {
    // Store all options when controller connects
    this.allCartridges = Array.from(this.cartridgeTarget.options)
    this.allPrimerTypes = Array.from(this.primerTypeTarget.options)
    this.allBullets = Array.from(this.bulletTarget.options)
    this.allPowders = Array.from(this.powderTarget.options)
    
    // Initially filter dropdowns
    this.filterCartridges()
    this.filterPrimerTypes()
    this.filterPowders()
    this.filterBullets()
  }

  filterCartridges() {
    const selectedCartridgeTypeId = this.cartridgeTypeTarget.value
    const cartridgeSelect = this.cartridgeTarget

    // Clear current options (except prompt)
    const promptOption = cartridgeSelect.querySelector('option[value=""]')
    cartridgeSelect.innerHTML = ""
    if (promptOption) {
      cartridgeSelect.appendChild(promptOption)
    }

    if (!selectedCartridgeTypeId) {
      // If no cartridge type selected, show no cartridges
      return
    }

    // Filter cartridges based on selected cartridge type
    this.cartridgesValue.forEach(cartridge => {
      if (cartridge.cartridge_type_ids.includes(parseInt(selectedCartridgeTypeId))) {
        const option = document.createElement("option")
        option.value = cartridge.id
        option.textContent = cartridge.name
        cartridgeSelect.appendChild(option)
      }
    })
  }

  filterPrimerTypes() {
    const selectedCartridgeTypeId = this.cartridgeTypeTarget.value
    const primerTypeSelect = this.primerTypeTarget

    // Clear current options (except prompt)
    const promptOption = primerTypeSelect.querySelector('option[value=""]')
    primerTypeSelect.innerHTML = ""
    if (promptOption) {
      primerTypeSelect.appendChild(promptOption)
    }

    if (!selectedCartridgeTypeId) {
      // If no cartridge type selected, show no primer types
      return
    }

    // Filter primer types based on selected cartridge type
    this.primerTypesValue.forEach(primerType => {
      if (primerType.cartridge_type_id.toString() === selectedCartridgeTypeId) {
        const option = document.createElement("option")
        option.value = primerType.id
        option.textContent = primerType.name
        primerTypeSelect.appendChild(option)
      }
    })
  }

  filterPowders() {
    const selectedCartridgeTypeId = this.cartridgeTypeTarget.value
    const powderSelect = this.powderTarget

    // Clear current options (except prompt)
    const promptOption = powderSelect.querySelector('option[value=""]')
    powderSelect.innerHTML = ""
    if (promptOption) {
      powderSelect.appendChild(promptOption)
    }

    if (!selectedCartridgeTypeId) {
      // If no cartridge type selected, show no powders
      return
    }

    // Filter powders based on selected cartridge type and sort by name
    const matchingPowders = this.powdersValue
      .filter(powder => powder.cartridge_type_ids.includes(parseInt(selectedCartridgeTypeId)))
      .sort((a, b) => a.name.localeCompare(b.name))

    matchingPowders.forEach(powder => {
      const option = document.createElement("option")
      option.value = powder.id
      option.textContent = powder.name
      powderSelect.appendChild(option)
    })
  }

  filterBullets() {
    const selectedBulletWeightId = this.bulletWeightTarget.value
    const bulletSelect = this.bulletTarget

    // Clear current options (except prompt)
    const promptOption = bulletSelect.querySelector('option[value=""]')
    bulletSelect.innerHTML = ""
    if (promptOption) {
      bulletSelect.appendChild(promptOption)
    }

    if (!selectedBulletWeightId) {
      // If no bullet weight selected, show no bullets
      return
    }

    // Find the selected bullet weight to get its weight value
    const selectedBulletWeight = this.bulletWeightsValue.find(bw => 
      bw.id.toString() === selectedBulletWeightId
    )

    if (!selectedBulletWeight) {
      return
    }

    // Filter bullets based on matching weight and sort by manufacturer then name
    const matchingBullets = this.bulletsValue
      .filter(bullet => parseFloat(bullet.weight) === parseFloat(selectedBulletWeight.weight))
      .sort((a, b) => {
        const manufacturerCompare = a.manufacturer_name.localeCompare(b.manufacturer_name)
        if (manufacturerCompare !== 0) return manufacturerCompare
        return a.name.localeCompare(b.name)
      })

    matchingBullets.forEach(bullet => {
      const option = document.createElement("option")
      option.value = bullet.id
      option.textContent = `${bullet.manufacturer_name} - ${bullet.name}`
      bulletSelect.appendChild(option)
    })
  }

  cartridgeTypeChanged() {
    this.filterCartridges()
    this.filterPrimerTypes()
    this.filterPowders()
    
    // Clear selections when cartridge type changes
    this.cartridgeTarget.value = ""
    this.primerTypeTarget.value = ""
    this.powderTarget.value = ""
  }

  bulletWeightChanged() {
    this.filterBullets()
    
    // Clear bullet selection when bullet weight changes
    this.bulletTarget.value = ""
  }
}