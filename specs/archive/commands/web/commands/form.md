# Form with Validation

name: "form"
description: "Generate React Hook Form + Zod form with MUI inputs"
parameters:
  - name: "name"
    description: "Form name in PascalCase (e.g., CreateIssueForm, LoginForm)"
    required: true
  - name: "fields"
    description: "JSON schema of fields (e.g., {email: 'email', password: 'password', name: 'string'})"
    required: true
  - name: "feature"
    description: "Feature folder name (e.g., issues, auth, members)"
    required: true

---

You are an expert React developer creating validated forms for the MunServ web admin portal.

## Task

Generate a form component `{{name}}` with React Hook Form and Zod validation.

## File Structure

```
src/features/{{feature}}/components/
├── {{name}}.tsx           # Form component
└── {{name}}.schema.ts     # Zod schema (optional, can be inline)
```

## Form Template

```typescript
import { type FC } from 'react';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import FormControl from '@mui/material/FormControl';
import FormHelperText from '@mui/material/FormHelperText';
import InputLabel from '@mui/material/InputLabel';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';

// Zod Schema
const {{name}}Schema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(1, 'Name is required'),
  // Add fields based on {{fields}}
});

type {{name}}Values = z.infer<typeof {{name}}Schema>;

interface {{name}}Props {
  onSubmit: (data: {{name}}Values) => void | Promise<void>;
  isSubmitting?: boolean;
  defaultValues?: Partial<{{name}}Values>;
}

export const {{name}}: FC<{{name}}Props> = ({
  onSubmit,
  isSubmitting = false,
  defaultValues,
}) => {
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<{{name}}Values>({
    resolver: zodResolver({{name}}Schema),
    defaultValues: {
      email: '',
      password: '',
      name: '',
      ...defaultValues,
    },
  });

  return (
    <Box
      component="form"
      onSubmit={handleSubmit(onSubmit)}
      sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}
    >
      {/* Text Input */}
      <Controller
        name="email"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            label="Email"
            type="email"
            error={!!errors.email}
            helperText={errors.email?.message}
            disabled={isSubmitting}
            fullWidth
            size="small"
          />
        )}
      />

      {/* Password Input */}
      <Controller
        name="password"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            label="Password"
            type="password"
            error={!!errors.password}
            helperText={errors.password?.message}
            disabled={isSubmitting}
            fullWidth
            size="small"
          />
        )}
      />

      {/* Select Input */}
      <Controller
        name="type"
        control={control}
        render={({ field }) => (
          <FormControl fullWidth size="small" error={!!errors.type}>
            <InputLabel>Type</InputLabel>
            <Select {...field} label="Type" disabled={isSubmitting}>
              <MenuItem value="option1">Option 1</MenuItem>
              <MenuItem value="option2">Option 2</MenuItem>
            </Select>
            {errors.type && (
              <FormHelperText>{errors.type.message}</FormHelperText>
            )}
          </FormControl>
        )}
      />

      <Button
        type="submit"
        variant="contained"
        disabled={isSubmitting}
        sx={{ mt: 1 }}
      >
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </Button>
    </Box>
  );
};
```

## Field Type Mappings

| Field Type | Zod Validator | MUI Component |
|------------|---------------|---------------|
| string | `z.string().min(1)` | `TextField` |
| email | `z.string().email()` | `TextField type="email"` |
| password | `z.string().min(8)` | `TextField type="password"` |
| number | `z.number().positive()` | `TextField type="number"` |
| select | `z.enum(['a', 'b'])` | `Select` with `MenuItem` |
| boolean | `z.boolean()` | `Checkbox` or `Switch` |
| date | `z.date()` | `DatePicker` |
| textarea | `z.string().max(500)` | `TextField multiline` |

## Zod Schema Examples

```typescript
// Required string
name: z.string().min(1, 'Name is required'),

// Optional string
notes: z.string().optional(),

// Email
email: z.string().email('Invalid email'),

// Phone (South African format)
phone: z.string().regex(/^\+27\d{9}$/, 'Invalid phone number'),

// Enum/Select
state: z.enum(['reported', 'confirmed', 'in_progress', 'fixed']),

// Number with range
heat: z.number().min(0).max(100),

// Date
reportedAt: z.date(),

// Coordinates
location: z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
}),

// Array of strings
tags: z.array(z.string()).min(1, 'At least one tag required'),

// Conditional validation
password: z.string().min(8),
confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
});
```

## Integration with Mutation

```typescript
import { useCreateIssue } from '../hooks';
import { CreateIssueForm } from './CreateIssueForm';

const CreateIssuePage: FC = () => {
  const createIssue = useCreateIssue();

  const handleSubmit = async (data: CreateIssueFormValues) => {
    await createIssue.mutateAsync(data);
    // Navigate or show success
  };

  return (
    <CreateIssueForm
      onSubmit={handleSubmit}
      isSubmitting={createIssue.isPending}
    />
  );
};
```

## MUI Form Styling

```typescript
// Form container
<Box
  component="form"
  sx={{
    display: 'flex',
    flexDirection: 'column',
    gap: 2,
    maxWidth: 400,
    mx: 'auto',
    p: 3,
  }}
>

// Text field
<TextField
  size="small"
  fullWidth
  variant="outlined"  // Default
/>

// Button group
<Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end', mt: 2 }}>
  <Button variant="outlined" onClick={onCancel}>
    Cancel
  </Button>
  <Button type="submit" variant="contained">
    Submit
  </Button>
</Box>
```

## Output

1. Generate form component with all fields
2. Create Zod schema based on field types
3. Use Controller for all inputs (controlled components)
4. Include proper error display for each field
5. Handle loading/submitting state
6. Export from feature's components/index.ts
