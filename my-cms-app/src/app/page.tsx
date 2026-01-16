//app/page.tsx
'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'
import { supabase } from '@/lib/supabaseClient'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  const login = async () => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    console.log('LOGIN RESULT:', { data, error })

    if (error) {
      setError(error.message)
      return
    }

    console.log('LOGIN SUCCESS')

    // ✅ login สำเร็จ → ไป /admin
    router.push('/admin/activities')
  }

  return (
    <div>
      <h1>Admin Login</h1>

      <input
        placeholder="Email"
        onChange={e => setEmail(e.target.value)}
      />

      <input
        type="password"
        placeholder="Password"
        onChange={e => setPassword(e.target.value)}
      />

      <button onClick={login}>Login</button>

      {error && <p>{error}</p>}
    </div>
  )
}
