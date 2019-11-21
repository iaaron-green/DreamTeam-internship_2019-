package com.app.controllers;


import com.app.configmail.MyConstants;
import com.app.configtoken.JwtTokenProvider;
import com.app.entities.Profile;
import com.app.entities.User;
import com.app.repository.UserRepository;
import com.app.services.ProfileService;
import com.app.services.UserService;
import com.app.validators.JWTLoginSuccessResponse;
import com.app.validators.LoginRequest;
import com.app.validators.UserValidator;
import com.app.validators.ValidationErrorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import java.util.Optional;
import java.util.UUID;

import static com.app.configtoken.Constants.TOKEN_PREFIX;

@RestController
@CrossOrigin
@RequestMapping("/api/users")
public class AuthorizationController {

   private ValidationErrorService validationErrorService;
   private UserService userService;
   private UserValidator userValidator;
   private JwtTokenProvider tokenProvider;
   private AuthenticationManager authenticationManager;
   private ProfileService profileService;

   @Autowired
   private JavaMailSender emailSender;

   @Autowired
   private UserRepository userRepository;

   @Autowired
   public AuthorizationController(ValidationErrorService validationErrorService, UserService userService,
                         UserValidator userValidator,
                         JwtTokenProvider tokenProvider, AuthenticationManager authenticationManager, ProfileService profileService) {
      this.validationErrorService = validationErrorService;
      this.userService = userService;
      this.userValidator = userValidator;
      this.tokenProvider = tokenProvider;
      this.authenticationManager = authenticationManager;
      this.profileService = profileService;
   }

   @PostMapping("/login")
   public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest, BindingResult result){
      ResponseEntity<?> errorMap = validationErrorService.mapValidationService(result);
      if(errorMap != null)
         return errorMap;

      String userName = loginRequest.getUsername();
      boolean isActivated = userService.activationCode(userName);
      if(!isActivated)
         return new ResponseEntity<>(HttpStatus.LOCKED);

      User newUser = userRepository.findByUsername(userName);
      Profile newProfile = profileService.saveProfile(new Profile(newUser));

      Authentication authentication = authenticationManager.authenticate(
              new UsernamePasswordAuthenticationToken(
                      loginRequest.getUsername(),
                      loginRequest.getPassword()
              )
      );

      SecurityContextHolder.getContext().setAuthentication(authentication);
      String jwt = TOKEN_PREFIX +  tokenProvider.provideToken(authentication);

      return ResponseEntity.ok(new JWTLoginSuccessResponse(true, jwt));
   }

   @PostMapping("/register")
   public ResponseEntity<?> registerUser(@Valid @RequestBody User user, BindingResult result) throws MessagingException {
      userValidator.validate(user,result);

      ResponseEntity<?> errorMap = validationErrorService.mapValidationService(result);
      if(errorMap != null) return errorMap;

      if(userRepository.findByUsername(user.getUsername()) != null)
      {
         return new ResponseEntity<>(HttpStatus.LOCKED);
      }
      user.setActivationCode(UUID.randomUUID().toString());

      User newUser = userService.saveUser(user);
      MimeMessage message = emailSender.createMimeMessage();

      boolean multipart = true;

      MimeMessageHelper helper = null;
      try {
         helper = new MimeMessageHelper(message, multipart, "utf-8");
      } catch (MessagingException e) {
         e.printStackTrace();
      }

      String htmlMsg = "<h3>Grampus</h3>"
              +"<img src='https://i.ibb.co/yNsKQ53/image.png'>" +
              "<p>You're profile is register! Thank you.<p>" +
               "To activate you're profile visit next link: http://localhost:8081/api/users/activate/"+ newUser.getActivationCode();

      message.setContent(htmlMsg, "text/html");

      helper.setTo(user.getUsername());

      helper.setSubject("Profile registration(GRAMPUS)");

      this.emailSender.send(message);

      return new ResponseEntity<>(newUser, HttpStatus.CREATED);
   }

   @GetMapping("/activate/{code}")
   public String activate(@PathVariable String code) {

   userService.activateUser(code);
      return "<img style='width:100%' 'height:100%' 'text-align: center' src='https://cdn1.savepice.ru/uploads/2019/11/21/bcadc0172fce5e6a398bb4edcdf8bf7a-full.jpg'>";
   }
}
