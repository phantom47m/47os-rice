// 47 Glass - Tab open/close sounds
// MV3 service workers can't use Audio() directly, use offscreen document

let hasOffscreen = false;

async function ensureOffscreen() {
  if (hasOffscreen) return;
  try {
    await chrome.offscreen.createDocument({
      url: 'offscreen.html',
      reasons: ['AUDIO_PLAYBACK'],
      justification: 'Play tab open/close sounds'
    });
    hasOffscreen = true;
  } catch (e) {
    // Already exists
    hasOffscreen = true;
  }
}

async function playSound(file) {
  try {
    await ensureOffscreen();
    chrome.runtime.sendMessage({ action: 'playSound', file: file });
  } catch (e) {
    // Silently fail if offscreen not supported (older Chrome)
  }
}

chrome.tabs.onCreated.addListener(() => {
  playSound('tab-open.ogg');
});

chrome.tabs.onRemoved.addListener(() => {
  playSound('tab-close.ogg');
});
