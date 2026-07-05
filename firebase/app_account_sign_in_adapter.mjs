import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  updateProfile,
} from 'firebase/auth';

export function createAppAccountSignInAdapter({
  auth,
  allowLocalEmulatorSignIn = false,
}) {
  return {
    async signInLocalAppAccount({
      email,
      password,
      editableDisplayName,
      providerProfilePictureUrl = null,
      removeProviderProfilePicture = false,
    }) {
      if (!allowLocalEmulatorSignIn) {
        throw new Error(
          'Local App Account sign-in is only available for emulator tests',
        );
      }

      const credential = await signInOrCreateLocalEmulatorUser({
        auth,
        email,
        password,
      });
      await updateProfile(credential.user, {
        displayName: editableDisplayName,
        photoURL: providerProfilePictureUrl,
      });

      await credential.user.reload();

      return appAccountFromFirebaseUser(credential.user, {
        removeProviderProfilePicture,
      });
    },
  };
}

export function productionAppAccountProviderForPlatform(platform) {
  if (platform === 'android') {
    return 'google';
  }

  if (platform === 'ios') {
    return 'apple';
  }

  throw new Error(`Unsupported App Account platform: ${platform}`);
}

function appAccountFromFirebaseUser(
  user,
  { removeProviderProfilePicture = false } = {},
) {
  const providerProfilePictureUrl =
    removeProviderProfilePicture || !user.photoURL ? null : user.photoURL;

  return {
    uid: user.uid,
    memberProfile: {
      editableDisplayName: user.displayName,
      providerProfilePictureUrl,
      profilePictureSource: providerProfilePictureUrl ? 'provider' : 'default',
      canRemoveProviderProfilePicture: Boolean(providerProfilePictureUrl),
      canUploadReplacementProfilePicture: false,
    },
  };
}

async function signInOrCreateLocalEmulatorUser({ auth, email, password }) {
  try {
    return await createUserWithEmailAndPassword(auth, email, password);
  } catch (error) {
    if (error.code !== 'auth/email-already-in-use') {
      throw error;
    }

    return signInWithEmailAndPassword(auth, email, password);
  }
}
