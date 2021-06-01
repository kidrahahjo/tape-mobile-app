String refactorPhoneNumber(String phone) {
  phone = phone.replaceAll(" ", "");
  if (phone.startsWith('+91')) {
    // indian phone number
    return phone;
  } else if (phone.startsWith('+')) {
    // non-indian phone number
    return null;
  } else {
    try {
      String num = '+91' + int.parse(phone).toString();
      if (num.length == 13) {
        // indian phone number
        return num;
      } else {
        // non-indian phone number
        return null;
      }
    } catch (e) {
      // non-indian phone number
      return null;
    }
  }
}

String refactorOTP(String otp) {
  if (otp == null || otp.length != 6) {
    return null;
  } else {
    return otp;
  }
}
