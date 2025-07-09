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
  if (dropdown) dropdown.style.display = "none";
  errorDiv.textContent = "";
}

document.addEventListener("turbo:load", function () {
  document.querySelectorAll("input[data-dropdown-target]").forEach((input) => {
    input.addEventListener("input", () => filterDropdown(input.id));
  });
  document.querySelectorAll(".input-dropdown input").forEach((input) => {
    input.addEventListener("input", function () {
      filterDropdown(this.id);
    });

    input.addEventListener("focus", function () {
      document.querySelectorAll(".dropdown-list").forEach((list) => {
        list.style.display = "none";
      });

      const list = document.getElementById(this.id + "-list");
      if (list) {
        list.style.display = "block";
      }
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
      document
        .querySelectorAll(".dropdown-list")
        .forEach((list) => (list.style.display = "none"));
    }
  });

  const form = document.querySelector("form");
  const sourceInput = document.getElementById("source-input");
  const destinationInput = document.getElementById("destination-input");

if (form) {
  form.addEventListener("submit", function (e) {
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

    if (!source || !destination) {
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

window.filterDropdown = filterDropdown;
window.selectOption = selectOption;
