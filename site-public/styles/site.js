const simulator = document.getElementById('tarif-simulator');

if (simulator) {
  let opener;
  const total = simulator.querySelector('#sim-total');
  const children = simulator.querySelector('#sim-children');
  const adults = simulator.querySelector('#sim-adults');
  const result = simulator.querySelector('#sim-result');
  const fields = [total, children, adults];

  function validate() {
    const values = fields.map((field) => Number(field.value));
    const valid = fields.every((field, index) => field.value !== '' && Number.isSafeInteger(values[index]) && values[index] >= Number(field.min));
    if (!valid) {
      result.textContent = 'Saisissez des nombres entiers valides.';
    } else if (values[0] !== values[1] + values[2]) {
      result.textContent = 'Le nombre d’enfants et d’adultes doit correspondre au total.';
    } else {
      // No public Finance simulation endpoint is present in this checkout.
      result.textContent = 'Le calcul est momentanément indisponible. Réessayez dans un instant.';
    }
  }

  fields.forEach((field) => field.addEventListener('input', validate));
  document.querySelectorAll('[data-open-simulator]').forEach((button) => {
    button.addEventListener('click', () => {
      opener = button;
      validate();
      simulator.showModal();
      total.focus();
    });
  });
  simulator.addEventListener('close', () => opener?.focus());
  simulator.addEventListener('click', (event) => {
    const bounds = simulator.getBoundingClientRect();
    if (event.target === simulator && (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom)) simulator.close();
  });
}
