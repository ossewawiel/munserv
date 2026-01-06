import { type FC } from 'react';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';

interface SelectOption {
  value: string;
  label: string;
}

interface SelectProps {
  label?: string;
  error?: string;
  options: SelectOption[];
  placeholder?: string;
  value?: string;
  onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void;
  disabled?: boolean;
  fullWidth?: boolean;
  name?: string;
  id?: string;
}

export const Select: FC<SelectProps> = ({
  label,
  error,
  options,
  placeholder,
  value,
  onChange,
  disabled,
  fullWidth = true,
  name,
  id,
}) => {
  return (
    <TextField
      select
      label={label}
      error={!!error}
      helperText={error}
      value={value ?? ''}
      onChange={onChange}
      disabled={disabled}
      fullWidth={fullWidth}
      size="small"
      variant="outlined"
      name={name}
      id={id}
    >
      {placeholder && (
        <MenuItem value="" disabled>
          {placeholder}
        </MenuItem>
      )}
      {options.map((option) => (
        <MenuItem key={option.value} value={option.value}>
          {option.label}
        </MenuItem>
      ))}
    </TextField>
  );
};
