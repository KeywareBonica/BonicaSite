document.addEventListener('DOMContentLoaded', function()
 {
    const form = document.getElementById('registrationForm');
    
    // use profile input
      const fullName = document.getElementById('fullName');
      const surname = document.getElementById('surname');
      const password = document.getElementById('password');
      const confirmPassword = document.getElementById('confirmPassword');
      const contact = document.getElementById('contact');
      const email = document.getElementById('email');
      const province = document.getElementById('province');
      const city = document.getElementById('city');
      const town = document.getElementById('town');
      const houseNumber = document.getElementById('houseNumber');
      const streetName = document.getElementById('streetName');
      const postalCode = document.getElementById('postalCode');
      const notification = document.getElementById('notification');
 
      //validation
      function validateFullName()
      {
        const value = fullName.value.trim();
        if (value === '')
            {
                showError(fullName, 'Full name is required', 'fullNameError');
                return false;
            } 
            else if (!/^[a-zA-Z\s]+$/.test(value))
            {
                showError(fullName, 'Full name should contain only letters', 'fullNameError')
            }
            else 
            {
                showSuccess(fullName, 'fullNameError');
                return true;
            }
      }

      function validateSurname()
      {
        const value = surname.value.trim();
        if (value === '')
            {
                showError(surname, 'Surname is required', 'SurnaameError');
                return false;
            } 
            else if (!/^[a-zA-Z\s]+$/.test(value))
            {
                showError(Surname, 'Surname should contain only letters', 'SurnameError')
            }
            else 
            {
                showSuccess(Surname, 'SurnameError');
                return true;
            }
      }
      function validatePassword() {
        const value = password.value;
        if (value === '') 
            {
                showError(password, 'Password is required', 'passwordError');
                return false;
        
            } 
        
            else if (value.length < 8) 
            {
                showError(password, 'Password must be at least 8 characters', 'passwordError');
                return false;
            }            
        
            else 
            {
                 showSuccess(password, 'passwordError');
                 return true;
            }
      }

      function validateConfirmPassword()
      {
        const value = confirmPassword.value;
        if (value === '')
        {
            showError(cornfirmpassword, 'Please confirm password.', 'Confirm Password')
            return false;
        }
        else if (value !== password.value)
        {
            showError(confirmPassword, 'Password does not match', 'Confirm Password');
            return false;
        }
        else
        {
            showSuccess(confirmPassword, 'confirmpassworderror')
            return true;
        }
      }
});