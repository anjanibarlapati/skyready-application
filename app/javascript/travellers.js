document.addEventListener("turbo:load", function () {
  const incrementBtn = document.querySelector(".counter-btn:last-of-type");
  const decrementBtn = document.querySelector(".counter-btn:first-of-type");
  const input = document.getElementById("travellers_count");

  function updateButtonState() {
    const count = parseInt(input.value);
    decrementBtn.disabled = count <= 1;
    incrementBtn.disabled = count >= 9;

    decrementBtn.classList.toggle("disabled", decrementBtn.disabled);
    incrementBtn.classList.toggle("disabled", incrementBtn.disabled);
  }

  if (incrementBtn && decrementBtn && input) {
    incrementBtn.addEventListener("click", () => {
      let count = parseInt(input.value);
      if (count < 9) {
        input.value = count + 1;
        updateButtonState();
      }
    });

    decrementBtn.addEventListener("click", () => {
      let count = parseInt(input.value);
      if (count > 1) {
        input.value = count - 1;
        updateButtonState();
      }
    });

    updateButtonState();
  }
});
