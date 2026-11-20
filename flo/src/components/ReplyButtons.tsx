import { Mail, MessageSquare } from "lucide-react";
import CopyButton from "@/components/CopyButton";
import { primaryBtn, secondaryBtn } from "@/components/ui";

// Envoi d'un message déjà rédigé depuis la messagerie ou les SMS de l'artisan (Flo n'envoie rien lui-même).
export default function ReplyButtons({ email, phone, subject, text, verb = "Répondre" }: {
  email: string | null; phone: string | null; subject: string; text: string; verb?: string;
}) {
  return (
    <div className="flex flex-wrap gap-2 text-sm">
      {email && <a href={`mailto:${email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(text)}`} className={`${primaryBtn} flex items-center gap-2`}><Mail size={16} aria-hidden />{verb} par e-mail</a>}
      {phone && <a href={`sms:${phone.replace(/[^\d+]/g, "")}?body=${encodeURIComponent(text)}`} className={`${secondaryBtn} flex items-center gap-2`}><MessageSquare size={16} aria-hidden />{verb} par SMS</a>}
      <CopyButton text={text} label="Copier le message" />
    </div>
  );
}
