let userClickedInput = false;

function filterDropdown(inputId) {
  const input = document.getElementById(inputId);
  const filter = input.value.toUpperCase();
  const dropdown = document.getElementById(inputId + "-list");
  const items = dropdown.getElementsByClassName("dropdown-item");
  dropdown.style.display = "block";

  for (let i = 0; i < items.length; i++) {
    const txtValue = items[i].textContent || items[i].innerText;
    items[i].style.display =
      txtValue.toUpperCase().indexOf(filter) > -1 ? "" : "none";
  }
}

function selectOption(inputId, value) {
  const otherInputId = inputId === "source-input" ? "destination-input" : "source-input";
  const otherValue = document.getElementById(otherInputId).value;

  const input = document.getElementById(inputId);
  const dropdown = document.getElementById(inputId + "-list");
  const errorDiv = document.getElementById("search-error");

  if (value === otherValue) {
    errorDiv.textContent = "Source and destination cannot be the same.";
    input.value = "";
    if (dropdown) dropdown.style.display = "none";
    return;
  }

  input.value = value;
  input.setCustomValidity("");
  if (dropdown) dropdown.style.display = "none";
  errorDiv.textContent = "";
}

function clearValidationError(input) {
  input.setCustomValidity("");
  input.reportValidity();
  const errorDiv = document.getElementById("search-error");
  if (errorDiv) {
    errorDiv.textContent = "";
  }
}

document.addEventListener("turbo:load", function () {
  document.querySelectorAll("input[data-dropdown-target]").forEach((input) => {
    const dropdown = document.getElementById(input.id + "-list");

    input.addEventListener("mousedown", function () {
      userClickedInput = true;
    });

    input.addEventListener("input", () => {
      input.setCustomValidity(""); 
      filterDropdown(input.id);
    });

    input.addEventListener("focus", function () {
      clearValidationError(this)
      if (!userClickedInput && !this.value.trim()) {
        return;
      }

      clearValidationError(this);

      document.querySelectorAll(".dropdown-list").forEach((list) => {
        list.style.display = "none";
      });
      if (dropdown) dropdown.style.display = "block";

      userClickedInput = false;
    });

    input.addEventListener("click", function () {
      clearValidationError(this);

      document.querySelectorAll(".dropdown-list").forEach((list) => {
        list.style.display = "none";
      });
      if (dropdown) dropdown.style.display = "block";
    });
  });

  document.querySelectorAll(".dropdown-item").forEach((item) => {
    item.addEventListener("click", () => {
      const value = item.getAttribute("data-value");
      const inputId = item.parentElement.id.replace("-list", "");
      selectOption(inputId, value);
    });
  });

  document.addEventListener("click", function (event) {
    if (!event.target.closest(".input-dropdown")) {
      document.querySelectorAll(".dropdown-list")
        .forEach((list) => (list.style.display = "none"));
    }
  });

  const form = document.querySelector("form");
  const sourceInput = document.getElementById("source-input");
  const destinationInput = document.getElementById("destination-input");

  if (form) {
    form.addEventListener("submit", function (e) {
      let valid = true;

      const source = sourceInput.value.trim();
      const destination = destinationInput.value.trim();

      const validCities = [
        "Delhi", "Mumbai", "Bengaluru", "Hyderabad", "Chennai",
        "Kolkata", "Ahmedabad", "Pune", "Goa", "Jaipur"
      ];

      const matchedSource = validCities.find(city => city.toLowerCase() === source.toLowerCase());
      const matchedDestination = validCities.find(city => city.toLowerCase() === destination.toLowerCase());

      const errorDiv = document.getElementById("search-error");
      errorDiv.textContent = "";

      if (!source) {
        sourceInput.setCustomValidity("Please fill in this field");
        sourceInput.reportValidity();
        valid = false;
      } else {
        sourceInput.setCustomValidity("");
      }

      if (!destination) {
        destinationInput.setCustomValidity("Please fill in this field");
        destinationInput.reportValidity();
        valid = false;
      } else {
        destinationInput.setCustomValidity("");
      }

      if (!valid) {
        e.preventDefault();
        return;
      }

      if ((!matchedSource && source) || (!matchedDestination && destination)) {
        e.preventDefault();
        errorDiv.textContent = "Please select valid cities from dropdown.";
        return;
      }

      if (matchedSource && matchedDestination && matchedSource === matchedDestination) {
        e.preventDefault();
        errorDiv.textContent = "Source and destination cannot be the same.";
        return;
      }

      if (matchedSource) sourceInput.value = matchedSource;
      if (matchedDestination) destinationInput.value = matchedDestination;
    });
  }
});
