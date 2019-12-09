package com.app.services;

import com.app.DTO.DTOLikableProfile;
import com.app.DTO.DTOProfile;
import com.app.entities.Profile;
import com.app.exceptions.CustomException;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.security.Principal;
import java.util.List;
import java.util.Set;

@Service
public interface ProfileService {
    <S extends Profile> S saveProfile(S entity);

    Profile getProfileById(Long id) throws CustomException;

    DTOProfile getDTOProfileById(Long id, Principal principal) throws CustomException;

    Boolean updateProfile(DTOProfile profile, String principalName);

    void saveProfilePhoto(MultipartFile file, Long id, Principal principal) throws CustomException;

    List<Profile> getAllProfiles() throws CustomException;

    Page<DTOLikableProfile> getAllProfilesForLike(Principal principal, String searchParam, Integer page, Integer size);

    Boolean changeSubscription(Long profileId, Principal principal) throws CustomException;

    String saveImgInFtp(MultipartFile file, String directory) throws CustomException;

}
