import { type FC } from 'react';
import TextField, { type TextFieldProps } from '@mui/material/TextField';

interface InputProps extends Omit<TextFieldProps, 'error'> {
  error?: string;
}

export const Input: FC<InputProps> = ({ label, error, ...props }) => {
  return (
    <TextField
      label={label}
      error={!!error}
      helperText={error}
      fullWidth
      size="small"
      variant="outlined"
      {...props}
    />
  );
};
