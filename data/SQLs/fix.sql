UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/usercontent/camera/' WHERE  `key`='camera.url';
UPDATE emulator_settings SET `value`='/services/assets/public/usercontent/camera/' WHERE  `key`='imager.location.output.camera';
UPDATE emulator_settings SET `value`='/services/assets/public/usercontent/camera/thumbnail/' WHERE  `key`='imager.location.output.thumbnail';
UPDATE emulator_settings SET `value`='0' WHERE `key`='console.mode';