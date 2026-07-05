import { deleteApp, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signOut } from 'firebase/auth';
import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import {
  createAppAccountSignInAdapter,
  productionAppAccountProviderForPlatform,
} from './app_account_sign_in_adapter.mjs';

let app;
let auth;
let adapter;

before(() => {
  app = initializeApp(
    {
      apiKey: 'demo-key',
      authDomain: 'demo-fasting-app.firebaseapp.com',
      projectId: 'demo-fasting-app',
    },
    'app-account-sign-in-adapter-test',
  );
  auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', {
    disableWarnings: true,
  });
  adapter = createAppAccountSignInAdapter({
    auth,
    allowLocalEmulatorSignIn: true,
  });
});

beforeEach(async () => {
  await signOut(auth);
});

after(async () => {
  await deleteApp(app);
});

test('local emulator App Account sign-in identifies the signed-in user', async () => {
  const appAccount = await adapter.signInLocalAppAccount({
    email: 'local-member@example.test',
    password: 'local-emulator-password',
    editableDisplayName: 'Local Member',
    providerProfilePictureUrl: 'https://example.test/local-member.png',
  });

  assert.equal(auth.currentUser.uid, appAccount.uid);
  assert.equal(appAccount.memberProfile.editableDisplayName, 'Local Member');
  assert.equal(
    appAccount.memberProfile.providerProfilePictureUrl,
    'https://example.test/local-member.png',
  );
  assert.equal(appAccount.memberProfile.profilePictureSource, 'provider');
  assert.equal(appAccount.memberProfile.canRemoveProviderProfilePicture, true);
  assert.equal(appAccount.memberProfile.canUploadReplacementProfilePicture, false);
});

test('local App Account can fall back to the default profile picture', async () => {
  const appAccount = await adapter.signInLocalAppAccount({
    email: 'default-picture-member@example.test',
    password: 'local-emulator-password',
    editableDisplayName: 'Default Picture Member',
    providerProfilePictureUrl: 'https://example.test/default-picture-member.png',
    removeProviderProfilePicture: true,
  });

  assert.equal(appAccount.memberProfile.profilePictureSource, 'default');
  assert.equal(appAccount.memberProfile.providerProfilePictureUrl, null);
});

test('production App Account provider shape follows the mobile platform', () => {
  assert.equal(productionAppAccountProviderForPlatform('android'), 'google');
  assert.equal(productionAppAccountProviderForPlatform('ios'), 'apple');
});
