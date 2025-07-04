# SkyReady - One Tap to Take Off ✈️
**SkyReady** is a user-friendly flight booking web application built using *Ruby on Rails*. It enables users to search, view, and book flights with seat availability and dynamic fare calculations based on occupancy and travel dates.


## 📚 Table of Contents

- [Features](#📋-features)
- [Technologies Used](#🛠️-technologies-used)
- [Requirements](#🗒️-requirements)
- [Installation](#📥-installation)
- [Usage](#🚀-usage)
- [Contribution](#🤝-contribution)
- [Contact](#📧-contact)

## 📋 Features

SkyReady provides a seamless experience for travelers to search and book flights between cities with features:
1. **🔎 Search Flights:**
    - Users can search flights by selecting the departure city, arrival city, and date.
2. **📄 Flight Details:**
    - Shows each flight's number, from/to cities, departure and arrival time, and how many seats are left.
3. **👥 Choose Passengers and Class:**
    - Users can enter how many people are traveling.
    - They can also choose the class of travel: Economy, Second Class, or First Class.
4. **✈️ See Only Available Flights:**
    - Flights that are full will not be shown.
    - If no flights are found, a message will display: "No Flights Available".
5. **💰 Calculate Ticket Price:**
    - Prices change based on how many seats are left and how close the travel date is.
    - Fewer seats or closer travel dates may cost more.
6. **🔁 Round Trip Support:**
    - Users can book a return flight too.
    - A 5% discount is given for round trips.


## 🛠️ Technologies Used

- 💎 **Ruby on Rails:** Full-stack web development framework.
- 🧪 **RSpec:** Unit and feature testing.
- 🎯 **Rubocop:** Code linting and style checking.
- 🌐 **HTML with Embedded Ruby:** Used to create dynamic views by combining HTML with Ruby code.
- 🎨 **CSS:** Styling the front-end interface and responsive design.
- 🛠️ **GitHub Actions:** Automated testing and CI/CD pipelines.



## 🗒️ Requirements

Make sure you have the following installed before starting:

1. Install [Ruby](https://www.ruby-lang.org/en/downloads/) on your system. Make sure that Ruby version >= 3.0
2. Install Rails using below command. Make sure that Rails version >= 7.0 
   ```bash
   gem install rails
   ```
3. Install Bundler for managing Ruby gems. Bundler usually comes with Ruby, if not you can install or update it using:
   ```bash
   gem install bundler
   ```
4. Install [Git](https://git-scm.com/downloads) on your system.


## 📥 Installation

- Clone the repository:
  ```bash
  git clone git@github.com:anjanibarlapati/skyready-application.git
  ```
- Install Ruby dependencies:
  ```bash
  bundle install --path vendor/bundle
  ```


## 🚀 Usage


- Run test suites:
  ```bash
  bundle exec rspec
  ```
- Run linting:
  ```bash
  bin/rubocop -f github
  ```
- Start the server:
  ```bash
  rails server      
  ```
- Visit the app in your browser:
  ```bash
  http://localhost:3000
  ```

## 🤝 Contribution:
#### If you'd like to contribute, follow these steps:
- Clone repository:
    ```bash
    git clone git@github.com:anjanibarlapati/skyready-application.git
    ```
- Create a new branch for your feature.
    ```bash
    git checkout -b branch-name
    ```
- Push your branch to GitHub:
    ```bash
    git push origin branch-name
    ```
- Open a Pull Request to *main* branch.

## 📧 Contact:
For any questions or queries, 

Please contact, [anjanibarlapati@gmail.com](anjanibarlapati@gmail.com)

### Thank You 😃
